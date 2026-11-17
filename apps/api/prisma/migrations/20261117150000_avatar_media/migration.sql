-- AlterTable
ALTER TABLE "users" ADD COLUMN     "avatar_url" TEXT;

-- CreateTable
CREATE TABLE "user_avatars" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "url" TEXT NOT NULL,
    "is_current" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_avatars_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_uploads" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "file_id" TEXT NOT NULL,
    "s3_key" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'processing',
    "variant_url" TEXT,
    "error" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "media_uploads_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "user_avatars_user_id_created_at_idx" ON "user_avatars"("user_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "media_uploads_file_id_key" ON "media_uploads"("file_id");

-- CreateIndex
CREATE UNIQUE INDEX "media_uploads_s3_key_key" ON "media_uploads"("s3_key");

-- CreateIndex
CREATE INDEX "media_uploads_user_id_idx" ON "media_uploads"("user_id");

-- AddForeignKey
ALTER TABLE "user_avatars" ADD CONSTRAINT "user_avatars_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_uploads" ADD CONSTRAINT "media_uploads_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

