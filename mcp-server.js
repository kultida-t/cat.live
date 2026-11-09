#!/usr/bin/env node

/**
 * Model Context Protocol (MCP) Server for Core Portal Log Ingestion.
 * Exposes a tool to submit logs to the Core Portal via API Key.
 * API keys can be passed per request or configured through CORE_PORTAL_API_KEY.
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
 *           "CORE_PORTAL_URL": "http://localhost:5001",
 *           "CORE_PORTAL_API_KEY": "sk_univ_..."
 *         }
 *       }
 *     }
 *   }
 */

import readline from 'readline';

const serverUrl = process.env.CORE_PORTAL_URL || 'http://localhost:5001';
const defaultApiKey = process.env.CORE_PORTAL_API_KEY;

process.stdin.setEncoding('utf8');
process.stdout.setDefaultEncoding('utf8');
process.stderr.setDefaultEncoding('utf8');

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

function dateOnly(value) {
  return typeof value === 'string' && value.length >= 10 ? value.slice(0, 10) : undefined;
}

function normalizeCategory(category) {
  if (category === 'Bug FIX') return 'Bug Fix';
  return category;
}

function normalizeStatus(status) {
  if (status === 'Doing') return 'In Progress';
  return status;
}

rl.on('line', async (line) => {
  if (!line.trim()) return;

  try {
    const request = JSON.parse(line);
    const { jsonrpc, id, method, params } = request;

    if (jsonrpc !== '2.0') {
      sendResponse({
        jsonrpc: '2.0',
        id,
        error: { code: -32600, message: 'Invalid Request: Expected JSON-RPC 2.0' }
      });
      return;
    }

    switch (method) {
      case 'initialize':
        sendResponse({
          jsonrpc: '2.0',
          id,
          result: {
            protocolVersion: '2024-11-05',
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
                      description: 'The Core Portal API key (starts with sk_univ_). Optional when CORE_PORTAL_API_KEY is configured.'
                    },
                    appName: {
                      type: 'string',
                      description: 'The name of the application you are logging work for (e.g. "Eventlog UI", "Core API").'
                    },
                    applicationName: {
                      type: 'string',
                      description: 'Alias for appName, used by TukDaeng work-log drafts.'
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
                    startedAt: {
                      type: 'string',
                      description: 'Alias source for startDate. ISO timestamp values are converted to YYYY-MM-DD.'
                    },
                    stoppedAt: {
                      type: 'string',
                      description: 'Alias source for endDate. ISO timestamp values are converted to YYYY-MM-DD.'
                    },
                    category: {
                      type: 'string',
                      description: 'Task Category. Must be one of: Requirement, Design, Feature, Bug Fix, Testing, Refactor, Deploy / DevOps, Documentation, Meeting.'
                    },
                    status: {
                      type: 'string',
                      description: 'Task status to store with each log record (e.g. "Done", "In Progress", "Blocked"). Optional.'
                    },
                    total_hours: {
                      type: 'number',
                      description: 'Total hours spent for this work log. Use a value accepted by Core Portal, such as 2.5.'
                    },
                    totalHours: {
                      type: 'number',
                      description: 'Alias for total_hours, used by TukDaeng work-log drafts.'
                    },
                    logs: {
                      type: 'array',
                      items: {
                        type: 'string'
                      },
                      description: 'An array of task descriptions performed. Avoid duplicate tasks.'
                    }
                  },
                  required: ['category', 'logs']
                }
              },
              {
                name: 'list_my_apps',
                description: 'List the applications authorized for the current Core Portal API key, including each application\'s ongoing missions, objectives, and features. Free to call (no Gold deducted).',
                inputSchema: {
                  type: 'object',
                  properties: {
                    apiKey: {
                      type: 'string',
                      description: 'The Core Portal API key (starts with sk_univ_). Optional when CORE_PORTAL_API_KEY is configured.'
                    }
                  }
                }
              }
            ]
          }
        });
        break;

      case 'tools/call': {
        const { name, arguments: args } = params;

        if (name === 'list_my_apps') {
          const effectiveApiKey = args?.apiKey || defaultApiKey;

          if (!effectiveApiKey) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [
                  {
                    type: 'text',
                    text: 'Missing Core Portal API key. Pass apiKey or set CORE_PORTAL_API_KEY in the MCP server environment.'
                  }
                ],
                isError: true
              }
            });
            return;
          }

          try {
            const response = await fetch(`${serverUrl}/api/agent/apps`, {
              method: 'GET',
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
                  content: [
                    {
                      type: 'text',
                      text: `Failed to list apps. API returned error: ${data.error || response.statusText}`
                    }
                  ],
                  isError: true
                }
              });
              return;
            }

            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [
                  {
                    type: 'text',
                    text: typeof data === 'string' ? data : JSON.stringify(data, null, 2)
                  }
                ],
                isError: false
              }
            });
          } catch (apiErr) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [
                  {
                    type: 'text',
                    text: `Failed to connect to backend server at ${serverUrl}: ${apiErr.message}`
                  }
                ],
                isError: true
              }
            });
          }
          return;
        }

        if (name !== 'submit_logs') {
          sendResponse({
            jsonrpc: '2.0',
            id,
            error: { code: -32601, message: `Method not found: Tool '${name}' does not exist` }
          });
          return;
        }

        const {
          apiKey,
          appName,
          applicationName,
          appId,
          startDate,
          endDate,
          startedAt,
          stoppedAt,
          category,
          status,
          logs
        } = args;
        const effectiveAppName = appName ?? applicationName;
        const effectiveStartDate = startDate ?? dateOnly(startedAt);
        const effectiveEndDate = endDate ?? dateOnly(stoppedAt) ?? effectiveStartDate;
        const effectiveCategory = normalizeCategory(category);
        const effectiveStatus = normalizeStatus(status);
        const totalHours = args.total_hours ?? args.totalHours;
        const effectiveApiKey = apiKey || defaultApiKey;

        if (!effectiveStartDate || !effectiveEndDate || !Array.isArray(logs)) {
          sendResponse({
            jsonrpc: '2.0',
            id,
            result: {
              content: [
                {
                  type: 'text',
                  text: 'Missing required log fields. Provide startDate/endDate or startedAt/stoppedAt, plus logs as an array.'
                }
              ],
              isError: true
            }
          });
          return;
        }

        if (!effectiveApiKey) {
          sendResponse({
            jsonrpc: '2.0',
            id,
            result: {
              content: [
                {
                  type: 'text',
                  text: 'Missing Core Portal API key. Pass apiKey or set CORE_PORTAL_API_KEY in the MCP server environment.'
                }
              ],
              isError: true
            }
          });
          return;
        }

        try {
          // Make HTTP POST call to Express Server
          const response = await fetch(`${serverUrl}/api/agent/logs`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'X-API-Key': effectiveApiKey
            },
            body: JSON.stringify({
              app_id: appId,
              app_name: effectiveAppName,
              start_date: effectiveStartDate,
              end_date: effectiveEndDate,
              category: effectiveCategory,
              status: effectiveStatus,
              total_hours: totalHours,
              logs
            })
          });

          const data = await response.json();

          if (!response.ok) {
            sendResponse({
              jsonrpc: '2.0',
              id,
              result: {
                content: [
                  {
                    type: 'text',
                    text: `Failed to submit logs. API returned error: ${data.error || response.statusText}`
                  }
                ],
                isError: true
              }
            });
            return;
          }

          sendResponse({
            jsonrpc: '2.0',
            id,
            result: {
              content: [
                {
                  type: 'text',
                  text: `Success: ${data.message || 'Logs submitted successfully.'}`
                }
              ],
              isError: false
            }
          });
        } catch (apiErr) {
          sendResponse({
            jsonrpc: '2.0',
            id,
            result: {
              content: [
                {
                  type: 'text',
                  text: `Failed to connect to backend server at ${serverUrl}: ${apiErr.message}`
                }
              ],
              isError: true
            }
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
