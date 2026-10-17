CREATE TABLE "restored_colors" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "service_date" DATE NOT NULL,
    "color_id" VARCHAR(32) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "restored_colors_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "restored_colors_user_id_service_date_key"
ON "restored_colors"("user_id", "service_date");

CREATE INDEX "restored_colors_user_id_service_date_idx"
ON "restored_colors"("user_id", "service_date");

ALTER TABLE "restored_colors"
ADD CONSTRAINT "restored_colors_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "restored_colors"
ADD CONSTRAINT "restored_colors_color_id_fkey"
FOREIGN KEY ("color_id") REFERENCES "colors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
