import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface ProcessExternalFileInput {
  s3Key: string;
  outputPath: string;
  presetNames: string[];
  callbackUrl: string;
}

/** เรียก CloudImageLab ด้วย key ที่อยู่ฝั่ง server เท่านั้น */
@Injectable()
export class CloudImageLabClient {
  constructor(private readonly config: ConfigService) {}

  async processExternalFile(input: ProcessExternalFileInput): Promise<{ fileId: string }> {
    const baseUrl = this.config.get<string>('CLOUDIMAGELAB_BASE_URL');
    const apiKey = this.config.get<string>('CLOUDIMAGELAB_API_KEY');
    if (!baseUrl || !apiKey) {
      throw new ServiceUnavailableException('ระบบประมวลผลรูปยังไม่ได้ตั้งค่า');
    }
    const res = await fetch(`${baseUrl}/api/files/process`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Api-Key': apiKey },
      body: JSON.stringify(input),
    });
    if (!res.ok) {
      throw new ServiceUnavailableException('ส่งรูปไปประมวลผลไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
    return (await res.json()) as { fileId: string };
  }
}
