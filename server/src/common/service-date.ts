// 서비스 날짜: 하루(오늘의 색, 하루 한 호, 같은 색 잠금)를 나누는 기준 날짜.
// 서버가 SERVICE_TIME_ZONE(기본 Asia/Seoul)의 달력으로 정한다. 앱이 보낸 "오늘"은 믿지 않는다.

/** 그 시간대 이름을 이 Node가 아는지(IANA 시간대인지) 확인한다. 예: 'Asia/Seoul' → true, 'Mars/Base' → false */
export function isValidTimeZone(timeZone: string): boolean {
  if (!timeZone) return false;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone });
    return true;
  } catch {
    return false;
  }
}

/** now가 그 시간대에서 며칠인지 "YYYY-MM-DD"로 돌려준다. 예: 2026-10-14T15:00:00Z, 'Asia/Seoul' → "2026-10-15" */
export function serviceDate(now: Date, timeZone: string): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(now);
  const part = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((p) => p.type === type)?.value;
  return `${part('year')}-${part('month')}-${part('day')}`;
}
