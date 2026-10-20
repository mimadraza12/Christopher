--liquibase formatted sql

--changeset imad.raza:2026-10-19-001-raw-appraisals-loan-amount-scale-3 labels:ddl
--comment: Loan_Amount Nullable(Decimal(18, 2)) -> Nullable(Decimal(18, 3)). Scale goes up (no precision lost), but the integer part shrinks from 16 to 15 digits, so the precondition halts if any value would overflow. MODIFY COLUMN rewrites the column in every part (a mutation); mutations_sync = 2 makes Liquibase wait for it. Re-running is safe: modifying to the same type is a no-op.
--preconditions onFail:HALT onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM raw.appraisals WHERE abs(Loan_Amount) >= toDecimal64(1000000000000000, 2)
ALTER TABLE raw.appraisals
    MODIFY COLUMN Loan_Amount Nullable(Decimal(18, 3))
    SETTINGS mutations_sync = 2;
--rollback ALTER TABLE raw.appraisals MODIFY COLUMN Loan_Amount Nullable(Decimal(18, 2)) SETTINGS mutations_sync = 2;
