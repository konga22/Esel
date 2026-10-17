import { HttpStatus } from '@nestjs/common';

export const APP_ERRORS = {
  VALIDATION: {
    status: HttpStatus.BAD_REQUEST,
    message: '보낸 값의 형식이 맞지 않아요.',
    hint: 'details에 적힌 항목을 고쳐 다시 보내 주세요.',
  },
  AUTH_REQUIRED: {
    status: HttpStatus.UNAUTHORIZED,
    message: '로그인이 필요해요.',
    hint: '로그인한 뒤 다시 시도해 주세요.',
  },
  TOKEN_EXPIRED: {
    status: HttpStatus.UNAUTHORIZED,
    message: '로그인이 만료됐어요.',
    hint: 'refresh token으로 새 토큰을 받아 주세요.',
  },
  WRONG_CREDENTIALS: {
    status: HttpStatus.UNAUTHORIZED,
    message: '이메일 또는 비밀번호가 맞지 않아요.',
    hint: '입력한 내용을 확인해 주세요.',
  },
  FORBIDDEN: {
    status: HttpStatus.FORBIDDEN,
    message: '이 작업을 할 권한이 없어요.',
    hint: '내 것만 바꿀 수 있어요.',
  },
  NOT_FOUND: {
    status: HttpStatus.NOT_FOUND,
    message: '찾을 수 없어요.',
    hint: '없거나 아직 볼 수 없는 내용이에요.',
  },
  EMAIL_TAKEN: {
    status: HttpStatus.CONFLICT,
    message: '이미 가입한 이메일이에요.',
    hint: '로그인해 주세요.',
  },
  MASTHEAD_TAKEN: {
    status: HttpStatus.CONFLICT,
    message: '이미 있는 이름이에요.',
    hint: '다른 영문 이름을 골라 주세요.',
  },
  PROFILE_EXISTS: {
    status: HttpStatus.CONFLICT,
    message: '이미 잡지를 만들었어요.',
    hint: '내 잡지에서 이어 주세요.',
  },
  CHOICE_LOCKED: {
    status: HttpStatus.CONFLICT,
    message: '오늘 호를 발행해서 색을 바꿀 수 없어요.',
    hint: '내일 새 색을 골라 주세요.',
  },
  ISSUE_ALREADY_PUBLISHED: {
    status: HttpStatus.CONFLICT,
    message: '오늘 호는 이미 발행했어요.',
    hint: '하루에 한 호만 발행할 수 있어요.',
  },
  MEDIA_NOT_READY: {
    status: HttpStatus.CONFLICT,
    message: '사진 올리기가 아직 끝나지 않았어요.',
    hint: '업로드를 마친 뒤 다시 시도해 주세요.',
  },
  ALREADY_FRIENDS: {
    status: HttpStatus.CONFLICT,
    message: '이미 친구예요.',
    hint: '친구 목록에서 확인해 주세요.',
  },
  REQUEST_EXISTS: {
    status: HttpStatus.CONFLICT,
    message: '이미 보낸 요청이 있어요.',
    hint: '상대가 답할 때까지 기다려 주세요.',
  },
  TWIN_STATE: {
    status: HttpStatus.CONFLICT,
    message: '지금 단계에서는 할 수 없는 작업이에요.',
    hint: '트윈의 현재 단계를 확인해 주세요.',
  },
  TWIN_CONSENT_REQUIRED: {
    status: HttpStatus.CONFLICT,
    message: '두 사람 모두 동의해야 공개할 수 있어요.',
    hint: '상대의 동의를 기다려 주세요.',
  },
  RESTORE_LIMIT: {
    status: HttpStatus.CONFLICT,
    message: '이번 달 복원 기회를 모두 썼어요.',
    hint: '다음 달에 다시 복원할 수 있어요.',
  },
  MEDIA_TOO_LARGE: {
    status: HttpStatus.PAYLOAD_TOO_LARGE,
    message: '사진이 너무 커요.',
    hint: '15MB 이하로 올려 주세요.',
  },
  MEDIA_TYPE: {
    status: HttpStatus.UNSUPPORTED_MEDIA_TYPE,
    message: '사진 파일만 올릴 수 있어요.',
    hint: 'JPEG·PNG·HEIC를 골라 주세요.',
  },
  MASTHEAD_INVALID: {
    status: HttpStatus.UNPROCESSABLE_ENTITY,
    message: '이름은 영문 소문자 2~10자예요.',
    hint: 'a부터 z까지만 써 주세요.',
  },
  COLOR_NOT_CANDIDATE: {
    status: HttpStatus.UNPROCESSABLE_ENTITY,
    message: '오늘 후보에 없는 색이에요.',
    hint: '오늘의 세 가지 색 중에서 골라 주세요.',
  },
  RESTORE_NOT_ALLOWED: {
    status: HttpStatus.UNPROCESSABLE_ENTITY,
    message: '이 날짜는 복원할 수 없어요.',
    hint: '이번 달 지난 빈 날짜만 복원할 수 있어요.',
  },
  SHARE_NOT_PUBLIC: {
    status: HttpStatus.UNPROCESSABLE_ENTITY,
    message: '공개된 표지만 공유할 수 있어요.',
    hint: '발행하거나 공동 공개에 동의한 뒤 공유해 주세요.',
  },
  RATE_LIMITED: {
    status: HttpStatus.TOO_MANY_REQUESTS,
    message: '요청이 너무 많아요.',
    hint: '잠시 뒤 다시 시도해 주세요.',
  },
} as const;

export type AppErrorCode = keyof typeof APP_ERRORS;
