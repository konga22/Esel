import {
  exceedsPixelLimit,
  inspectImage,
  MAX_MEDIA_PIXELS,
  unusedMediaCutoff,
} from './media.rules.js';

describe('exceedsPixelLimit', () => {
  it('아이폰 48MP(8064×6048)·갤럭시 50MP(8160×6120) 사진은 받는다', () => {
    expect(exceedsPixelLimit(8064, 6048)).toBe(false);
    expect(exceedsPixelLimit(8160, 6120)).toBe(false);
  });

  it('가로×세로가 정확히 상한이면 받고, 1화소라도 넘으면 거절한다', () => {
    expect(exceedsPixelLimit(MAX_MEDIA_PIXELS, 1)).toBe(false);
    expect(exceedsPixelLimit(MAX_MEDIA_PIXELS + 1, 1)).toBe(true);
  });

  it('작은 파일에 거대한 해상도를 적은 압축 폭탄(65535×65535)을 거절한다', () => {
    expect(exceedsPixelLimit(65_535, 65_535)).toBe(true);
  });

  it('해상도를 읽지 못한 사진(HEIC)은 여기서 판단하지 않는다', () => {
    expect(exceedsPixelLimit(null, null)).toBe(false);
  });
});

describe('unusedMediaCutoff', () => {
  it('지금보다 정확히 24시간 전 시각을 기준으로 삼는다', () => {
    expect(
      unusedMediaCutoff(new Date('2026-11-12T03:00:00.000Z')).toISOString(),
    ).toBe('2026-11-11T03:00:00.000Z');
  });
});

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
