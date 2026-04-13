-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "paymentMethod" TEXT NOT NULL DEFAULT 'COD',
ADD COLUMN     "requiresPayout" BOOLEAN NOT NULL DEFAULT false;
