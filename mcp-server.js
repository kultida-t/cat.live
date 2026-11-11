#!/usr/bin/env node

/**
 * Model Context Protocol (MCP) Server for Core Portal Log Ingestion.
 * Exposes a tool to submit logs to the Core Portal via API Key.
 *
 * Running:
 *   node mcp-server.js
 *
 * Configuration for Cursor / Windsurf / Claude Desktop:
 *   {
 *     "mcpServers": {
 *       "core-portal": {
 *         "command": "node",
 *         "args": ["/absolute/path/to/core_portal/mcp-server.js"],
 *         "env": {
 *           "CORE_PORTAL_URL": "http://localhost:5001"
 *         }
 *       }
 *     }
 *   }
 */

import readline from 'readline';
import fs from 'fs';
import path from 'path';

const serverUrl = process.env.CORE_PORTAL_URL || 'http://localhost:5001';

// Set up stdio reading
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

// Write JSON-RPC response to stdout
function sendResponse(response) {
  process.stdout.write(JSON.stringify(response) + '\n');
}

const ALLOWED_TOP_KEYS = new Set([
  'schema_version',
  'date',
  'timezone',
  'sessions',
  'limitations',
  'redactions_applied'
]);

const ALLOWED_SESSION_KEYS = new Set([
  'session_id',
  'tool',
  'project',
  'task_id',
  'mission',
  'objective',
  'feature',
  'objective_id',
  'feature_id',
  'messages'
]);

const IMAGE_OR_MEDIA_EXT_REGEX = /\.(png|jpe?g|webp|gif|svg|bmp|ico|tiff?|avif|heic|pdf|mp4|mov|webm|avi|mkv|zip|tar|gz)$/i;
const BASE64_IMAGE_DATA_URI_REGEX = /data:(image\/[a-zA-Z0-9.+-]+|video\/[a-zA-Z0-9.+-]+|application\/octet-stream);base64,[A-Za-z0-9+/=]{32,}/i;
const MAX_PROMPT_LOG_FILE_BYTES = 500 * 1024; // 500 KB per upload

/**
 * Detect binary or image magic bytes (even if a file was renamed to .json)
 */
function isBinaryOrImageBuffer(buf) {
  if (!Buffer.isBuffer(buf) || buf.length === 0) return false;
  // PNG: 89 50 4E 47
  if (buf.length >= 4 && buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4E && buf[3] === 0x47) return true;
  // JPEG: FF D8 FF
  if (buf.length >= 3 && buf[0] === 0xFF && buf[1] === 0xD8 && buf[2] === 0xFF) return true;
  // GIF: 47 49 46 38
  if (buf.length >= 4 && buf[0] === 0x47 && buf[1] === 0x49 && buf[2] === 0x46 && buf[3] === 0x38) return true;
  // RIFF / WEBP: 52 49 46 46 ... 57 45 42 50
  if (buf.length >= 12 && buf[0] === 0x52 && buf[1] === 0x49 && buf[2] === 0x46 && buf[3] === 0x46 &&
      buf[8] === 0x57 && buf[9] === 0x45 && buf[10] === 0x42 && buf[11] === 0x50) return true;
  // BMP: 42 4D
  if (buf.length >= 2 && buf[0] === 0x42 && buf[1] === 0x4D) return true;
  // PDF: 25 50 44 46
  if (buf.length >= 4 && buf[0] === 0x25 && buf[1] === 0x50 && buf[2] === 0x44 && buf[3] === 0x46) return true;
  // Null byte check in first 8KB (plain UTF-8 JSON never contains 0x00)
  const checkLen = Math.min(buf.length, 8192);
  for (let i = 0; i < checkLen; i++) {
    if (buf[i] === 0x00) return true;
  }
  return false;
}

/**
 * Strictly validate that the uploaded file & JSON payload match the Daily AI Prompt Log Schema 2.0
 */
function validatePromptLogPayload(data, filename) {
  // 1. Validate filename pattern: YYYY-MM-DD_ai-log.json or YYYY-MM-DD_<tool>_ai-log.json (and explicitly block image/media extensions)
  const cleanName = path.basename(String(filename || ''));
  if (IMAGE_OR_MEDIA_EXT_REGEX.test(cleanName)) {
    return {
      valid: false,
      reason: `Image and media files ("${cleanName}") are strictly prohibited. Only Daily AI Prompt Log JSON files ("YYYY-MM-DD_ai-log.json" or "YYYY-MM-DD_<tool>_ai-log.json") are allowed.`
    };
  }
  const fileMatch = cleanName.match(/^(\d{4}-\d{2}-\d{2})(?:_[a-zA-Z0-9._-]+)?_ai-log\.json$/);
  if (!fileMatch) {
    return {
      valid: false,
      reason: `Invalid filename "${cleanName}". Only files named "YYYY-MM-DD_ai-log.json" or "YYYY-MM-DD_<tool>_ai-log.json" (e.g., "2026-10-28_ai-log.json") are allowed.`
    };
  }
  const filenameDate = fileMatch[1];

  // 2. Validate top-level object and strict key whitelist
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return { valid: false, reason: 'Root JSON must be an object.' };
  }

  const topKeys = Object.keys(data);
  for (const k of topKeys) {
    if (!ALLOWED_TOP_KEYS.has(k)) {
      return {
        valid: false,
        reason: `Unexpected top-level field "${k}". Only Prompt Log Schema 2.0 fields (${Array.from(ALLOWED_TOP_KEYS).join(', ')}) are permitted.`
      };
    }
  }
  for (const reqKey of ALLOWED_TOP_KEYS) {
    if (!(reqKey in data)) {
      return {
        valid: false,
        reason: `Missing required top-level field "${reqKey}".`
      };
    }
  }

  // 3. Validate metadata fields
  if (data.schema_version !== '2.0') {
    return { valid: false, reason: `Unsupported schema_version "${data.schema_version}". Must be "2.0".` };
  }

  if (typeof data.date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(data.date) || isNaN(Date.parse(`${data.date}T00:00:00Z`))) {
    return { valid: false, reason: `Invalid "date" field "${data.date}". Must be a valid YYYY-MM-DD string.` };
  }

  if (data.date !== filenameDate) {
    return {
      valid: false,
      reason: `Filename date (${filenameDate}) does not match JSON "date" field (${data.date}).`
    };
  }

  if (typeof data.timezone !== 'string' || !data.timezone.trim()) {
    return { valid: false, reason: '"timezone" must be a non-empty string (e.g., "Asia/Bangkok").' };
  }

  if (!Array.isArray(data.limitations) || !data.limitations.every(item => typeof item === 'string')) {
    return { valid: false, reason: '"limitations" must be an array of strings.' };
  }

  if (typeof data.redactions_applied !== 'boolean') {
    return { valid: false, reason: '"redactions_applied" must be a boolean.' };
  }

  // 4. Validate sessions[]
  if (!Array.isArray(data.sessions) || data.sessions.length === 0) {
    return { valid: false, reason: '"sessions" must be a non-empty array.' };
  }

  for (let i = 0; i < data.sessions.length; i++) {
    const sess = data.sessions[i];
    if (!sess || typeof sess !== 'object' || Array.isArray(sess)) {
      return { valid: false, reason: `sessions[${i}] must be an object.` };
    }

    for (const sk of Object.keys(sess)) {
      if (!ALLOWED_SESSION_KEYS.has(sk)) {
        return { valid: false, reason: `Unexpected field "${sk}" in sessions[${i}].` };
      }
    }

    if (typeof sess.session_id !== 'string' || !sess.session_id.trim()) {
      return { valid: false, reason: `sessions[${i}].session_id must be a non-empty string.` };
    }

    if (typeof sess.tool !== 'string' || !sess.tool.trim()) {
      return { valid: false, reason: `sessions[${i}].tool must be a non-empty string.` };
    }

    if (sess.project !== null && sess.project !== undefined && typeof sess.project !== 'string') {
      return { valid: false, reason: `sessions[${i}].project must be a string or null.` };
    }

    if (sess.task_id !== null && sess.task_id !== undefined && typeof sess.task_id !== 'string') {
      return { valid: false, reason: `sessions[${i}].task_id must be a string or null.` };
    }

    // 5. Validate messages[]
    if (!Array.isArray(sess.messages) || sess.messages.length === 0) {
      return { valid: false, reason: `sessions[${i}].messages must be a non-empty array.` };
    }

    for (let j = 0; j < sess.messages.length; j++) {
      const msg = sess.messages[j];
      if (!msg || typeof msg !== 'object' || Array.isArray(msg)) {
        return { valid: false, reason: `sessions[${i}].messages[${j}] must be an object.` };
      }

      if (msg.role !== 'user' && msg.role !== 'assistant') {
        return { valid: false, reason: `sessions[${i}].messages[${j}].role must be "user" or "assistant".` };
      }

      if (msg.timestamp !== null && msg.timestamp !== undefined) {
        if (typeof msg.timestamp !== 'string' || isNaN(Date.parse(msg.timestamp))) {
          return { valid: false, reason: `sessions[${i}].messages[${j}].timestamp must be a valid ISO 8601 string or null.` };
        }
      }

      if (msg.role === 'user') {
        for (const mk of Object.keys(msg)) {
          if (mk !== 'role' && mk !== 'timestamp' && mk !== 'content') {
            return { valid: false, reason: `Unexpected field "${mk}" in user message sessions[${i}].messages[${j}].` };
          }
        }
        if (typeof msg.content !== 'string' || !msg.content.trim()) {
          return { valid: false, reason: `sessions[${i}].messages[${j}].content must be a non-empty string for role="user".` };
        }
        if (msg.content.includes(';base64,') && BASE64_IMAGE_DATA_URI_REGEX.test(msg.content)) {
          return {
            valid: false,
            reason: `Image or binary Base64 data URI detected in sessions[${i}].messages[${j}].content. Uploading images inside Prompt Logs is prohibited.`
          };
        }
      } else {
        for (const mk of Object.keys(msg)) {
          if (mk !== 'role' && mk !== 'timestamp' && mk !== 'summary') {
            return { valid: false, reason: `Unexpected field "${mk}" in assistant message sessions[${i}].messages[${j}].` };
          }
        }
        if (typeof msg.summary !== 'string' || !msg.summary.trim()) {
          return { valid: false, reason: `sessions[${i}].messages[${j}].summary must be a non-empty string for role="assistant".` };
        }
        if (msg.summary.includes(';base64,') && BASE64_IMAGE_DATA_URI_REGEX.test(msg.summary)) {
          return {
            valid: false,
            reason: `Image or binary Base64 data URI detected in sessions[${i}].messages[${j}].summary. Uploading images inside Prompt Logs is prohibited.`
          };
        }
      }
    }
  }

  // Verify that total Active Chat duration across sessions is > 0 seconds
  let totalActiveSeconds = 0;
  let maxSessionEndMsSoFar = null;
  for (const sess of data.sessions) {
    let prevInSessionMs = null;
    for (const msg of sess.messages || []) {
      const currMs = msg?.timestamp ? new Date(msg.timestamp).getTime() : NaN;
      if (!Number.isFinite(currMs) || Number.isNaN(currMs)) continue;
      let diffSec = 0;
      if (prevInSessionMs === null) {
        if (maxSessionEndMsSoFar !== null && currMs >= maxSessionEndMsSoFar) {
          diffSec = Math.max(0, Math.round((currMs - maxSessionEndMsSoFar) / 1000));
        }
      } else if (currMs >= prevInSessionMs) {
        diffSec = Math.max(0, Math.round((currMs - prevInSessionMs) / 1000));
      }
      prevInSessionMs = currMs;
      if (maxSessionEndMsSoFar === null || currMs > maxSessionEndMsSoFar) {
        maxSessionEndMsSoFar = currMs;
      }
      if (diffSec > 0) {
        const cap = msg.role === 'assistant' ? 1800 : 900;
        totalActiveSeconds += Math.min(diffSec, cap);
      }
    }
  }

  if (totalActiveSeconds <= 0) {
    return {
      valid: false,
      reason: `Total Active Chat duration is 0 seconds (ไม่สามารถบันทึกได้เนื่องจากผลรวมเวลาสนทนาจริง Active Chat เป็น 0 วินาที). Please ensure messages contain sequential ISO 8601 timestamps across at least 2 turns per the 3-Tier Timestamp Resolution Rules.`
    };
  }

  return { valid: true };
}

rl.on('line', async (line) => {
  if (!line.trim()) return;

  try {
    const request = JSON.parse(line);
    const { jsonrpc, id, method, params } = request;

    if (jsonrpc !== '2.0') {
      if (id !== undefined && id !== null) {
        sendResponse({
          jsonrpc: '2.0',
          id,
          error: { code: -32600, message: 'Invalid Request: Expected JSON-RPC 2.0' }
        });
      }
      return;
    }

    // JSON-RPC 2.0 Notifications (no 'id' field, e.g. notifications/initialized) MUST NOT receive a response
    if (id === undefined || id === null) {
      return;
    }

    switch (method) {
      case 'initialize':
        sendResponse({
          jsonrpc: '2.0',
          id,
          result: {
            protocolVersion: params?.protocolVersion || '2024-11-05',
            capabilities: {
              tools: {}
            },
            serverInfo: {
              name: 'core-portal-mcp-server',
              version: '1.0.0'
            }
          }
        });
        break;

      case 'ping':
        sendResponse({
          jsonrpc: '2.0',
          id,
          result: {}
        });
        break;

      case 'tools/list':
        sendResponse({
          jsonrpc: '2.0',
          id,
          result: {
            tools: [
              {
                name: 'submit_logs',
                description: 'Submit work activity logs for a specific application in the Core Portal logging system.',
                inputSchema: {
                  type: 'object',
                  properties: {
                    apiKey: {
                      type: 'string',
                      description: 'The Core Portal API key (starts with sk_univ_). Optional if CORE_PORTAL_API_KEY env var is set.'
                    },
                    appName: {
                      type: 'string',
                      description: 'The name of the application you are logging work for (e.g. "Eventlog UI", "Core API").'
                    },
                    appId: {
                      type: 'integer',
                      description: 'The database ID of the application (optional if appName is provided).'
                    },
                    startDate: {
                      type: 'string',
                      description: 'Start date of the work in YYYY-MM-DD format.'
                    },
                    endDate: {
                      type: 'string',
                      description: 'End date of the work in YYYY-MM-DD format.'
                    },
                    category: {
                      type: 'string',
                      description: 'Task Category. Must be one of: Requirement, Design, Feature, Bug Fix, Testing, Refactor, Deploy / DevOps, Documentation, Meeting.'
                    },
                    status: {
                      type: 'string',
                      description: 'Task Status. Optional. Must be one of: Doing, Done, Blocked.'
                    },
                    totalHours: {
                      type: 'number',
                      description: 'Total duration hours. Optional. If omitted and status is Doing, it defaults to null. For other statuses, it defaults to standard workday hours.'
                    },
                    logs: {
                      type: 'array',
                      items: {
                        type: 'string'
                      },
                      description: 'An array of task descriptions performed. Avoid duplicate tasks.'
                    },
                    objectiveName: {
                      type: 'string',
                      description: 'The fuzzy/exact name of the objective under the project\'s ongoing mission (optional).'
                    },
                    featureName: {
                      type: 'string',
                      description: 'The fuzzy/exact name of the feature under the selected objective (optional).'
                    },
                    objectiveId: {
                      type: 'integer',
                      description: 'The database ID of the objective (optional).'
                    },
                    featureId: {
                      type: 'integer',
                      description: 'The database ID of the feature (optional).'
                    }
                  },
                  required: ['startDate', 'endDate', 'category', 'logs']
                }
              },
              {
                name: 'list_my_apps',
                description: 'List all applications/projects that you are authorized to access and log work for.',
                inputSchema: {
                  type: 'object',
                  properties: {
                    apiKey: {
                      type: 'string',
                      description: 'The Core Portal API key (starts with sk_univ_). Optional if CORE_PORTAL_API_KEY env var is set.'
                    }
                  },
                  required: []
                }
              },
              {
                name: 'create_mission',
                description: 'Create a new project plan/Mission containing objectives and features for a project you are assigned to.',
                inputSchema: {
                  type: 'object',
                  properties: {
                    apiKey: {
                      type: 'string',
                      description: 'The Core Portal API key (starts with sk_univ_). Optional if CORE_PORTAL_API_KEY env var is set.'
                    },
                    missionName: {
                      type: 'string',
                      description: 'The name/title of the mission (e.g., "Authentication flow revamp").'
                    },
                    appName: {
                      type: 'string',
                      description: 'The name of the application/project to map this mission to (will be fuzzy matched under user permissions). Optional if appId is provided.'
                    },
                    appId: {
                      type: 'integer',
                      description: 'The database ID of the application (optional if appName is provided).'
                    },
                    startDate: {
                      type: 'string',
                      description: 'Start date of the mission in YYYY-MM-DD format.'
                    },
                    endDate: {
                      type: 'string',
                      description: 'End date of the mission in YYYY-MM-DD format.'
                    },
                    plannedHours: {
                      type: 'number',
                      description: 'Total planned hours budget for the mission (optional).'
                    },
                    objectives: {
                      type: 'array',
                      description: 'Objectives under this mission. They must be broken down with weights equally distributed by the backend.',
                      items: {
                        type: 'object',
                        properties: {
                          name: {
                            type: 'string',
                            description: 'The name of the objective.'
                          },
                          estimatedHours: {
                            type: 'number',
                            description: 'Estimated hours to complete this objective (optional).'
                          },
                          developer: {
                            type: 'string',
                            description: 'Assignee username, email, or sub (optional).'
                          },
                          features: {
                            type: 'array',
                            description: 'Sub-features or task scopes under this objective (optional).',
                            items: {
                              type: 'string'
                            }
                          }
                        },
                        required: ['name']
                      }
                    }
                  },
                  required: ['missionName', 'startDate', 'endDate', 'objectives']
                }
              },
              {
                name: 'upload_prompt_log',
                description: 'Upload a daily AI conversation prompt log JSON file (YYYY-MM-DD_ai-log.json) to Core Portal S3 storage using your Personal API Key and queue it for background Worker extraction (0 Gold fee).',
                inputSchema: {
                  type: 'object',
                  properties: {
                    apiKey: {
                      type: 'string',
                      description: 'The Core Portal Personal API key (starts with sk_univ_). Optional if CORE_PORTAL_API_KEY env var is set.'
                    },
                    filePath: {
                      type: 'string',
                      description: 'Path to the local JSON log file on disk (e.g., "./2026-10-28_ai-log.json"). Optional if jsonContent is provided.'
                    },
                    filename: {
                      type: 'string',
                      description: 'Filename to record (e.g., "2026-10-28_ai-log.json"). Optional; defaults to the basename of filePath or "<date>_ai-log.json".'
                    },
                    jsonContent: {
                      type: 'string',
                      description: 'The daily AI conversation log JSON string (Schema 2.0). Optional if filePath is provided.'
                    },
                    autoCreateWorklog: {
                      type: 'boolean',
                      description: 'Whether to automatically extract and create/merge Pending Worklogs from this Prompt Log upload (defaults to true). Set to false when the user asks not to create worklogs.'
                    }
                  },
                  required: []
                }
              }
            ]
          }
        });
        break;

      case 'tools/call': {
        const { name, arguments: args } = params;

        if (name === 'submit_logs') {
          const { 
            apiKey, 
            appName, 
            appId, 
            startDate, 
            endDate, 
            category, 
            logs, 
            status, 
            totalHours,
            objectiveName,
            featureName,
            objectiveId,
            featureId
          } = args || {};
          const effectiveApiKey = apiKey || process.env.CORE_PORTAL_API_KEY;
          try {
            const response = await fetch(`${serverUrl}/api/agent/logs`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'X-API-Key': effectiveApiKey
              },
              body: JSON.stringify({
                app_id: appId,
                app_name: appName,
                start_date: startDate,
                end_date: endDate,
                category,
                logs,
                status,
                total_hours: totalHours,
                objectiveName,
                featureName,
                objectiveId,
                featureId
              })
            });

            const data = await response.json();
            if (!response.ok) {
              sendResponse({
                jsonrpc: '2.0',
                id,
                result: {
                  content: [{ type: 'text', text: `Failed to submit logs. API returned error: ${data.error || response.statusText}` }],
                  isError: true
                }
              });
              return;
            }

            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: `Success: ${data.message || 'Logs submitted successfully.'} (หัก ${data.deductedGold !== undefined ? Math.abs(parseFloat(data.deductedGold)) : 0.25} Gold, ยอดคงเหลือ: ${data.remainingGold !== undefined ? data.remainingGold : 'N/A'} Gold)` }],
                isError: false
              }
            });
          } catch (apiErr) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: `Failed to connect to backend server at ${serverUrl}: ${apiErr.message}` }],
                isError: true
              }
            });
          }
        } else if (name === 'list_my_apps') {
          const { apiKey } = args || {};
          const effectiveApiKey = apiKey || process.env.CORE_PORTAL_API_KEY;
          try {
            const response = await fetch(`${serverUrl}/api/agent/apps`, {
              headers: {
                'X-API-Key': effectiveApiKey
              }
            });

            const data = await response.json();
            if (!response.ok) {
              sendResponse({
                jsonrpc: '2.0',
                id,
                result: {
                  content: [{ type: 'text', text: `Failed to list apps. API returned error: ${data.error || response.statusText}` }],
                  isError: true
                }
              });
              return;
            }

            const formattedText = (data.apps || []).map((app) => {
              const headerLine = `- ID: ${app.id} | App Name: "${app.name}"${app.project_name ? ` | Project Name: "${app.project_name}"` : ''} | Owner: ${app.owner || 'N/A'}${app.description ? ` (${app.description})` : ''}`;
              const missions = Array.isArray(app.ongoing_missions) ? app.ongoing_missions : [];
              if (missions.length === 0) return headerLine;
              const missionLines = missions.map((m) => {
                const objLines = (m.objectives || []).map((o) => {
                  const featStr = Array.isArray(o.features) && o.features.length > 0
                    ? o.features.map((f) => `[feature_id: ${f.feature_id}] "${f.feature_name}"`).join(', ')
                    : 'No sub-features';
                  return `    • Objective [objective_id: ${o.objective_id}]: "${o.objective_name}" (${o.status || 'Doing'})\n      Features: ${featStr}`;
                }).join('\n');
                return `  * Ongoing Mission [mission_id: ${m.mission_id}]: "${m.mission_name}"\n${objLines}`;
              }).join('\n');
              return `${headerLine}\n${missionLines}`;
            }).join('\n');
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: `Authorized Applications & Ongoing Missions:\n${formattedText || 'None'}\n\n(ฟรี ไม่หัก Gold)` }],
                isError: false
              }
            });
          } catch (apiErr) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: `Failed to connect to backend server at ${serverUrl}: ${apiErr.message}` }],
                isError: true
              }
            });
          }
        } else if (name === 'create_mission') {
          const { apiKey, missionName, appName, appId, startDate, endDate, plannedHours, objectives } = args || {};
          const effectiveApiKey = apiKey || process.env.CORE_PORTAL_API_KEY;
          try {
            const response = await fetch(`${serverUrl}/api/agent/missions`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'X-API-Key': effectiveApiKey
              },
              body: JSON.stringify({
                missionName,
                appName,
                appId,
                startDate,
                endDate,
                plannedHours,
                objectives
              })
            });

            const data = await response.json();
            if (!response.ok) {
              sendResponse({
                jsonrpc: '2.0',
                id,
                result: {
                  content: [{ type: 'text', text: `Failed to create mission. API returned error: ${data.error || response.statusText}` }],
                  isError: true
                }
              });
              return;
            }

            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: `Success: ${data.message || 'Mission created successfully.'} (หัก ${data.deductedGold !== undefined ? Math.abs(parseFloat(data.deductedGold)) : 0.25} Gold, ยอดคงเหลือ: ${data.remainingGold !== undefined ? data.remainingGold : 'N/A'} Gold)` }],
                isError: false
              }
            });
          } catch (apiErr) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: `Failed to connect to backend server at ${serverUrl}: ${apiErr.message}` }],
                isError: true
              }
            });
          }
        } else if (name === 'upload_prompt_log') {
          const { apiKey, filePath, filename, jsonContent, autoCreateWorklog, auto_worklog } = args;
          const resolvedAutoWorklog =
            autoCreateWorklog !== undefined
              ? autoCreateWorklog
              : auto_worklog !== undefined
              ? auto_worklog
              : undefined;
          const effectiveApiKey = apiKey || process.env.CORE_PORTAL_API_KEY;

          if (!effectiveApiKey) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: 'Failed to upload prompt log: apiKey is required.' }],
                isError: true
              }
            });
            return;
          }

          let payloadContent = jsonContent;
          let resolvedFilename = filename;

          if (filePath) {
            const actualBasename = path.basename(path.resolve(filePath));
            if (IMAGE_OR_MEDIA_EXT_REGEX.test(actualBasename)) {
              sendResponse({
                jsonrpc: '2.0',
                id,
                result: {
                  content: [{
                    type: 'text',
                    text: `Rejected by MCP Validator: Image/media file "${actualBasename}" is not allowed. Only Daily AI Prompt Log JSON files ("YYYY-MM-DD_ai-log.json") can be uploaded.`
                  }],
                  isError: true
                }
              });
              return;
            }
            if (!/^\d{4}-\d{2}-\d{2}_ai-log\.json$/.test(actualBasename)) {
              sendResponse({
                jsonrpc: '2.0',
                id,
                result: {
                  content: [{
                    type: 'text',
                    text: `Rejected by MCP Validator: Invalid file "${actualBasename}". Only Daily AI Prompt Log files named "YYYY-MM-DD_ai-log.json" are allowed.`
                  }],
                  isError: true
                }
              });
              return;
            }
            try {
              const resolvedPath = path.resolve(filePath);
              const rawBuffer = fs.readFileSync(resolvedPath);
              if (rawBuffer.length > MAX_PROMPT_LOG_FILE_BYTES) {
                sendResponse({
                  jsonrpc: '2.0',
                  id,
                  result: {
                    content: [{
                      type: 'text',
                      text: `Rejected by MCP Validator: File "${actualBasename}" size (${(rawBuffer.length / 1024).toFixed(1)} KB) exceeds the 500 KB maximum limit per upload.`
                    }],
                    isError: true
                  }
                });
                return;
              }
              if (isBinaryOrImageBuffer(rawBuffer)) {
                sendResponse({
                  jsonrpc: '2.0',
                  id,
                  result: {
                    content: [{
                      type: 'text',
                      text: `Rejected by MCP Validator: File "${actualBasename}" contains binary or image data (magic bytes detected). Image uploads are prohibited.`
                    }],
                    isError: true
                  }
                });
                return;
              }
              const rawFile = rawBuffer.toString('utf-8');
              payloadContent = JSON.parse(rawFile);
              resolvedFilename = actualBasename;
            } catch (readErr) {
              sendResponse({
                jsonrpc: '2.0',
                id,
                result: {
                  content: [{ type: 'text', text: `Failed to read or parse local file '${filePath}': ${readErr.message}` }],
                  isError: true
                }
              });
              return;
            }
          } else if (typeof payloadContent === 'string') {
            try {
              payloadContent = JSON.parse(payloadContent);
            } catch (parseErr) {
              sendResponse({
                jsonrpc: '2.0',
                id,
                result: {
                  content: [{ type: 'text', text: `Invalid jsonContent string: ${parseErr.message}` }],
                  isError: true
                }
              });
              return;
            }
          }

          if (!payloadContent || typeof payloadContent !== 'object') {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: 'Failed to upload prompt log: Either filePath or jsonContent must be provided.' }],
                isError: true
              }
            });
            return;
          }

          const serializedBytes = Buffer.byteLength(JSON.stringify(payloadContent, null, 2), 'utf-8');
          if (serializedBytes > MAX_PROMPT_LOG_FILE_BYTES) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{
                  type: 'text',
                  text: `Rejected by MCP Validator: Payload size (${(serializedBytes / 1024).toFixed(1)} KB) exceeds the 500 KB maximum limit per upload.`
                }],
                isError: true
              }
            });
            return;
          }

          if (!resolvedFilename && payloadContent.date) {
            resolvedFilename = `${payloadContent.date}_ai-log.json`;
          }

          const validation = validatePromptLogPayload(payloadContent, resolvedFilename);
          if (!validation.valid) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{
                  type: 'text',
                  text: `Rejected by MCP Prompt Log Schema Validator: ${validation.reason}`
                }],
                isError: true
              }
            });
            return;
          }

          try {
            const response = await fetch(`${serverUrl}/api/agent/prompt-logs`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'X-API-Key': effectiveApiKey
              },
              body: JSON.stringify({
                filename: resolvedFilename,
                content: payloadContent,
                ...(resolvedAutoWorklog !== undefined ? { autoCreateWorklog: resolvedAutoWorklog } : {})
              })
            });

            const data = await response.json();
            if (!response.ok) {
              sendResponse({
                jsonrpc: '2.0',
                id,
                result: {
                  content: [{ type: 'text', text: `Failed to upload prompt log. API returned error: ${data.error || response.statusText}` }],
                  isError: true
                }
              });
              return;
            }

            const up = data.upload || {};
            const autoWlStatus = up.auto_worklog === false ? 'Disabled (ไม่สร้าง Worklog อัตโนมัติ)' : 'Enabled (สกัดสร้าง Pending Worklog อัตโนมัติ)';
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{
                  type: 'text',
                  text: `Success: ${data.message || 'Prompt log uploaded to S3 successfully.'}\n- Upload ID: ${up.id}\n- User ID: ${up.user_sub}\n- Filename: ${up.filename}\n- S3 Key: ${up.s3_key}\n- Status: ${up.status}\n- Auto-Worklog: ${autoWlStatus}\n- Uploaded At: ${up.uploaded_at}\n(ฟรี ไม่หัก Gold)`
                }],
                isError: false
              }
            });
          } catch (apiErr) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [{ type: 'text', text: `Failed to connect to backend server at ${serverUrl}: ${apiErr.message}` }],
                isError: true
              }
            });
          }
        } else {
          sendResponse({
            jsonrpc: '2.0',
            id,
            error: { code: -32601, message: `Method not found: Tool '${name}' does not exist` }
          });
        }
        break;
      }

      default:
        // Respond with null result or ignore other lifecycle notifications
        sendResponse({
          jsonrpc: '2.0',
          id,
          result: {}
        });
        break;
    }
  } catch (err) {
    sendResponse({
      jsonrpc: '2.0',
      id: null,
      error: { code: -32700, message: `Parse error: Invalid JSON. Detail: ${err.message}` }
    });
  }
});
