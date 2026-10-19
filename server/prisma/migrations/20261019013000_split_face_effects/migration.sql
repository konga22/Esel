CREATE TYPE "FaceCrop" AS ENUM ('ORIGINAL', 'BEHIND_LOGO', 'BELOW_NECK');

ALTER TABLE "issues"
ADD COLUMN "face_crop" "FaceCrop" NOT NULL DEFAULT 'ORIGINAL',
ADD COLUMN "paint_stroke" BOOLEAN NOT NULL DEFAULT false;

UPDATE "issues"
SET
  "face_crop" = CASE "face_mode"::text
    WHEN 'BEHIND_MASTHEAD' THEN 'BEHIND_LOGO'::"FaceCrop"
    WHEN 'NECK_DOWN' THEN 'BELOW_NECK'::"FaceCrop"
    ELSE 'ORIGINAL'::"FaceCrop"
  END,
  "paint_stroke" = "face_mode"::text IN ('PAINT', 'PAINT_STROKE');

ALTER TABLE "issues" DROP COLUMN "face_mode";
DROP TYPE "FaceMode";

ALTER TABLE "issues"
ADD CONSTRAINT "issues_below_neck_without_paint_check"
CHECK ("face_crop" <> 'BELOW_NECK' OR "paint_stroke" = false);
