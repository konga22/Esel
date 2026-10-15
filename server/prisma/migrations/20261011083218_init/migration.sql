-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'SUSPENDED', 'DELETED');

-- CreateEnum
CREATE TYPE "MediaStatus" AS ENUM ('PENDING', 'READY', 'REJECTED', 'DELETED');

-- CreateEnum
CREATE TYPE "FaceMode" AS ENUM ('PLAIN', 'PAINT', 'BEHIND_MASTHEAD', 'NECK_DOWN');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" TEXT,
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "masthead" VARCHAR(10) NOT NULL,
    "issue_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "colors" (
    "id" VARCHAR(32) NOT NULL,
    "name_ko" VARCHAR(32) NOT NULL,
    "name_en" VARCHAR(32) NOT NULL,
    "hex" CHAR(7) NOT NULL,

    CONSTRAINT "colors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_palettes" (
    "id" UUID NOT NULL,
    "service_date" DATE NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "daily_palettes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_palette_colors" (
    "daily_palette_id" UUID NOT NULL,
    "color_id" VARCHAR(32) NOT NULL,
    "position" SMALLINT NOT NULL,

    CONSTRAINT "daily_palette_colors_pkey" PRIMARY KEY ("daily_palette_id","color_id")
);

-- CreateTable
CREATE TABLE "user_daily_choices" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "service_date" DATE NOT NULL,
    "color_id" VARCHAR(32) NOT NULL,
    "locked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_daily_choices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_assets" (
    "id" UUID NOT NULL,
    "owner_id" UUID NOT NULL,
    "storage_key" TEXT NOT NULL,
    "status" "MediaStatus" NOT NULL DEFAULT 'PENDING',
    "mime_type" VARCHAR(128) NOT NULL,
    "size_bytes" INTEGER NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "media_assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "issues" (
    "id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "service_date" DATE NOT NULL,
    "issue_number" INTEGER NOT NULL,
    "color_id" VARCHAR(32) NOT NULL,
    "media_id" UUID NOT NULL,
    "caption" VARCHAR(280) NOT NULL,
    "face_mode" "FaceMode" NOT NULL,
    "published_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "issues_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "profiles_user_id_key" ON "profiles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "profiles_masthead_key" ON "profiles"("masthead");

-- CreateIndex
CREATE UNIQUE INDEX "daily_palettes_service_date_key" ON "daily_palettes"("service_date");

-- CreateIndex
CREATE UNIQUE INDEX "daily_palette_colors_daily_palette_id_position_key" ON "daily_palette_colors"("daily_palette_id", "position");

-- CreateIndex
CREATE INDEX "user_daily_choices_service_date_color_id_idx" ON "user_daily_choices"("service_date", "color_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_daily_choices_user_id_service_date_key" ON "user_daily_choices"("user_id", "service_date");

-- CreateIndex
CREATE UNIQUE INDEX "media_assets_storage_key_key" ON "media_assets"("storage_key");

-- CreateIndex
CREATE INDEX "media_assets_owner_id_status_idx" ON "media_assets"("owner_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "issues_media_id_key" ON "issues"("media_id");

-- CreateIndex
CREATE INDEX "issues_service_date_color_id_published_at_idx" ON "issues"("service_date", "color_id", "published_at");

-- CreateIndex
CREATE UNIQUE INDEX "issues_author_id_service_date_key" ON "issues"("author_id", "service_date");

-- CreateIndex
CREATE UNIQUE INDEX "issues_author_id_issue_number_key" ON "issues"("author_id", "issue_number");

-- AddForeignKey
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_palette_colors" ADD CONSTRAINT "daily_palette_colors_daily_palette_id_fkey" FOREIGN KEY ("daily_palette_id") REFERENCES "daily_palettes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_palette_colors" ADD CONSTRAINT "daily_palette_colors_color_id_fkey" FOREIGN KEY ("color_id") REFERENCES "colors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_daily_choices" ADD CONSTRAINT "user_daily_choices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_daily_choices" ADD CONSTRAINT "user_daily_choices_color_id_fkey" FOREIGN KEY ("color_id") REFERENCES "colors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_assets" ADD CONSTRAINT "media_assets_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "issues" ADD CONSTRAINT "issues_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "issues" ADD CONSTRAINT "issues_color_id_fkey" FOREIGN KEY ("color_id") REFERENCES "colors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "issues" ADD CONSTRAINT "issues_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media_assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
