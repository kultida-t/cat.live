-- ตัวนับรหัส Cat ID สาธารณะ (รูปแบบ MAW000001, MAW000002, ...)
CREATE SEQUENCE "cat_public_id_seq";

-- CreateTable
CREATE TABLE "cats" (
    "id" UUID NOT NULL,
    "owner_id" UUID NOT NULL,
    "public_id" TEXT NOT NULL DEFAULT ('MAW' || lpad(nextval('cat_public_id_seq')::text, 6, '0')),
    "name" TEXT NOT NULL,
    "breed" TEXT,
    "sex" TEXT,
    "neutered" BOOLEAN,
    "birth_date" DATE,
    "photo_urls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "qr_payload" TEXT,
    "status" TEXT NOT NULL DEFAULT 'normal',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,
    "deleted_at" TIMESTAMPTZ,

    CONSTRAINT "cats_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cat_caretakers" (
    "cat_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role" TEXT NOT NULL,

    CONSTRAINT "cat_caretakers_pkey" PRIMARY KEY ("cat_id","user_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "cats_public_id_key" ON "cats"("public_id");

-- CreateIndex
CREATE INDEX "cats_owner_id_idx" ON "cats"("owner_id");

-- CreateIndex
CREATE INDEX "cat_caretakers_user_id_idx" ON "cat_caretakers"("user_id");

-- AddForeignKey
ALTER TABLE "cats" ADD CONSTRAINT "cats_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cat_caretakers" ADD CONSTRAINT "cat_caretakers_cat_id_fkey" FOREIGN KEY ("cat_id") REFERENCES "cats"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cat_caretakers" ADD CONSTRAINT "cat_caretakers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
