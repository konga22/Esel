-- 하네스 규칙을 DB가 직접 지키게 하는 CHECK 제약과 12색 기준 데이터.
-- 이미 공유된 init migration은 고치지 않고, 바꿀 내용은 이렇게 새 migration으로 더한다.

-- 12색: 저장소 루트 harness.json의 colors와 같은 key·hex·순서(sort_order). 이름은 디자인 생성기(lib.mjs PAINT)와 같다.
-- 앱이 동작하려면 꼭 있어야 하는 기준 데이터라 seed 스크립트가 아니라 migration에 넣는다(migrate deploy만으로 모든 DB에 들어감).
ALTER TABLE "colors" ADD COLUMN "sort_order" SMALLINT;

INSERT INTO "colors" ("id", "name_ko", "name_en", "hex", "sort_order") VALUES
  ('sage', '세이지', 'Sage', '#A8B5A0', 1),
  ('butter', '버터', 'Butter', '#E3C878', 2),
  ('powder', '파우더 블루', 'Powder blue', '#A9BDDC', 3),
  ('coral', '코랄', 'Coral', '#EE8C76', 4),
  ('lilac', '라일락', 'Lilac', '#BBA6D6', 5),
  ('terracotta', '테라코타', 'Terracotta', '#C2643F', 6),
  ('burgundy', '버건디', 'Burgundy', '#7A2735', 7),
  ('olive', '올리브', 'Olive', '#6F7445', 8),
  ('cream', '크림', 'Cream', '#E9DEC6', 9),
  ('charcoal', '차콜', 'Charcoal', '#3F4043', 10),
  ('camel', '카멜', 'Camel', '#C1945F', 11),
  ('cobalt', '코발트', 'Cobalt', '#2648B0', 12)
ON CONFLICT ("id") DO UPDATE SET
  "name_ko" = EXCLUDED."name_ko",
  "name_en" = EXCLUDED."name_en",
  "hex" = EXCLUDED."hex",
  "sort_order" = EXCLUDED."sort_order";

ALTER TABLE "colors" ALTER COLUMN "sort_order" SET NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "colors_sort_order_key" ON "colors"("sort_order");

-- 색 hex는 #과 대문자 16진수 6자리(harness.json과 같은 표기).
ALTER TABLE "colors" ADD CONSTRAINT "colors_hex_format_check" CHECK ("hex" ~ '^#[0-9A-F]{6}$');

-- 제호는 영문 소문자 2~10자(P14). 'Selin'과 'selin'이 함께 생기는 일을 DB가 막는다.
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_masthead_format_check" CHECK ("masthead" ~ '^[a-z]{2,10}$');

-- 발행한 호 수는 0 아래로 내려가지 않는다(창간 전 0, 발행할 때만 +1, P04).
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_issue_count_check" CHECK ("issue_count" >= 0);

-- 하루 후보 색은 1~3번 자리뿐이다(12색 중 하루 3가지, P17).
ALTER TABLE "daily_palette_colors" ADD CONSTRAINT "daily_palette_colors_position_check" CHECK ("position" BETWEEN 1 AND 3);

-- 개인 호수는 1호(창간호)부터다(P04).
ALTER TABLE "issues" ADD CONSTRAINT "issues_issue_number_check" CHECK ("issue_number" >= 1);
