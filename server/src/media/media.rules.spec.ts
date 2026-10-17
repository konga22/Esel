import { inspectImage } from './media.rules.js';

function png(width: number, height: number): Buffer {
  const bytes = Buffer.alloc(24);
  Buffer.from('89504e470d0a1a0a', 'hex').copy(bytes);
  bytes.writeUInt32BE(width, 16);
  bytes.writeUInt32BE(height, 20);
  return bytes;
}

describe('inspectImage', () => {
  it('PNG 실제 서명과 해상도를 읽는다', () => {
    expect(inspectImage(png(1080, 1440))).toEqual({
      mimeType: 'image/png',
      width: 1080,
      height: 1440,
    });
  });

  it('확장자가 아닌 바이트 내용으로 사진을 구분한다', () => {
    expect(inspectImage(Buffer.from('not an image'))).toBeNull();
  });
});
