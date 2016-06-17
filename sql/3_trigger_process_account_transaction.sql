CREATE OR REPLACE FUNCTION process_account_transaction() RETURNS TRIGGER AS $process_transaction$
BEGIN
  -- У всех счетов и транзакции должна быть одинаковая валюта

  IF NEW.operation_id IS NOT NULL THEN
    PERFORM * FROM OPENBIL_OPERATIONS WHERE ID = NEW.operation_id AND from_account_id = NEW.from_account_id AND to_account_id = NEW.to_account_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Operation (#%) has wrong accounts', NEW.operation_id;
    END IF;

  END IF;

  PERFORM * FROM OPENBILL_ACCOUNTS where id = NEW.from_account_id and amount_currency = NEW.amount_currency;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Account (from #%) has wrong currency', NEW.from_account_id;
  END IF;

  PERFORM * FROM OPENBILL_ACCOUNTS where id = NEW.to_account_id and amount_currency = NEW.amount_currency;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Account (to #%) has wrong currency', NEW.to_account_id;
  END IF;

  -- установить last_transaction_id, counts и _at
  UPDATE OPENBILL_ACCOUNTS SET amount_cents = amount_cents - NEW.amount_cents, last_transaction_id = NEW.id, last_transaction_at = NEW.created_at, transactions_count = transactions_count + 1 WHERE id = NEW.from_account_id;
  UPDATE OPENBILL_ACCOUNTS SET amount_cents = amount_cents + NEW.amount_cents, last_transaction_id = NEW.id, last_transaction_at = NEW.created_at, transactions_count = transactions_count + 1 WHERE id = NEW.to_account_id;

  return NEW;
END

$process_transaction$ LANGUAGE plpgsql;

CREATE TRIGGER process_account_transaction
  AFTER INSERT ON OPENBILL_TRANSACTIONS FOR EACH ROW EXECUTE PROCEDURE process_account_transaction();

-- current_user

CREATE OR REPLACE FUNCTION add_current_user_to_transaction() RETURNS TRIGGER AS $add_current_user_to_transaction$
BEGIN
  NEW.username := current_user;
  RETURN NEW;
END
$add_current_user_to_transaction$ LANGUAGE plpgsql;

CREATE TRIGGER add_current_user_to_transaction
  BEFORE INSERT ON OPENBILL_TRANSACTIONS FOR EACH ROW EXECUTE PROCEDURE add_current_user_to_transaction();
