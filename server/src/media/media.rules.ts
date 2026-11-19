export const MAX_MEDIA_SIZE_BYTES = 15 * 1024 * 1024;
export const ALLOWED_MEDIA_TYPES = [
  'image/jpeg',
  'image/png',
  'image/heic',
] as const;

/** 호·트윈에 연결되지 않은 사진을 이 시간 동안 아무도 건드리지 않으면 정리 대상이 된다. */
export const UNUSED_MEDIA_MAX_AGE_MS = 24 * 60 * 60 * 1000;
/** 한 번 정리할 때 지우는 최대 개수. 남은 것은 다음 정리 때 이어서 지운다. */
export const MEDIA_CLEANUP_BATCH_SIZE = 100;

/** 마지막 변경(updatedAt)이 이 시각보다 이르면 "오래된" 사진이다. */
export function unusedMediaCutoff(now: Date): Date {
  return new Date(now.getTime() - UNUSED_MEDIA_MAX_AGE_MS);
}

export interface ImageInfo {
  mimeType: (typeof ALLOWED_MEDIA_TYPES)[number];
  width: number | null;
  height: number | null;
}

export function inspectImage(bytes: Buffer): ImageInfo | null {
  if (isPng(bytes)) {
    if (bytes.length < 24) return null;
    const width = bytes.readUInt32BE(16);
    const height = bytes.readUInt32BE(20);
    if (width < 1 || height < 1) return null;
    return { mimeType: 'image/png', width, height };
  }

  const jpegSize = jpegDimensions(bytes);
  if (jpegSize) return { mimeType: 'image/jpeg', ...jpegSize };

  if (isHeic(bytes)) {
    return { mimeType: 'image/heic', width: null, height: null };
  }
  return null;
}

function isPng(bytes: Buffer): boolean {
  const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  return signature.every((value, index) => bytes[index] === value);
}

function jpegDimensions(
  bytes: Buffer,
): { width: number; height: number } | null {
  if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) return null;
  const sizeMarkers = new Set([
    0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce,
    0xcf,
  ]);
  let offset = 2;
  while (offset + 3 < bytes.length) {
    if (bytes[offset] !== 0xff) {
      offset += 1;
      continue;
    }
    const marker = bytes[offset + 1];
    if (marker === undefined || marker === 0xd9 || marker === 0xda) break;
    if (marker === 0xff || marker === 0x00) {
      offset += 1;
      continue;
    }
    const length = bytes.readUInt16BE(offset + 2);
    if (length < 2 || offset + 2 + length > bytes.length) return null;
    if (sizeMarkers.has(marker) && length >= 7) {
      const height = bytes.readUInt16BE(offset + 5);
      const width = bytes.readUInt16BE(offset + 7);
      return width > 0 && height > 0 ? { width, height } : null;
    }
    offset += 2 + length;
  }
  return null;
}

function isHeic(bytes: Buffer): boolean {
  if (bytes.length < 12 || bytes.toString('ascii', 4, 8) !== 'ftyp') {
    return false;
  }
  const brands = bytes.toString('ascii', 8, Math.min(bytes.length, 40));
  return ['heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'].some((brand) =>
    brands.includes(brand),
  );
}
