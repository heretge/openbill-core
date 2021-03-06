CREATE                TABLE OPENBILL_GOODS (
  owner_id            integer,
  id                  BIGSERIAL PRIMARY KEY,
  group_id            integer,
  title               varchar(255) not null,
  unit                varchar(128) not null default 'count',
  details             text,
  meta                hstore not null default ''::hstore,
  created_at          timestamp without time zone default current_timestamp,
  updated_at          timestamp without time zone default current_timestamp
);

CREATE UNIQUE INDEX index_goods_on_id ON OPENBILL_GOODS USING btree (id);
CREATE UNIQUE INDEX index_goods_on_group_id ON OPENBILL_GOODS USING btree (group_id);
CREATE INDEX index_goods_on_meta ON OPENBILL_GOODS USING gin (meta);

CREATE                TABLE OPENBILL_GOODS_AVAILABILITIES (
  id                  BIGSERIAL PRIMARY KEY,
  account_id          integer not null,
  good_id             integer not null,
  value               decimal not null default 0,
  created_at          timestamp without time zone default current_timestamp,
  updated_at          timestamp without time zone default current_timestamp,
  foreign key (account_id) REFERENCES OPENBILL_GOODS (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  foreign key (good_id) REFERENCES OPENBILL_GOODS (id) ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE UNIQUE INDEX index_goods_availabilities
  ON OPENBILL_GOODS_AVAILABILITIES
  USING btree (account_id, good_id);

ALTER TABLE OPENBILL_TRANSACTIONS ADD column good_id integer;
ALTER TABLE OPENBILL_TRANSACTIONS ADD column good_value decimal;
ALTER TABLE OPENBILL_TRANSACTIONS ADD column good_unit varchar(128);
ALTER TABLE OPENBILL_TRANSACTIONS
  ADD FOREIGN KEY(good_id) REFERENCES OPENBILL_GOODS(id)
  ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE OPENBILL_TRANSACTIONS
  ADD CONSTRAINT good_data_existence CHECK (
    good_id IS NULL OR (good_id IS NOT NULL AND good_value IS NOT NULL AND good_unit IS NOT NULL)
  );

CREATE OR REPLACE FUNCTION process_account_transaction_with_good() RETURNS TRIGGER AS $process_transaction$
DECLARE
  result text;
BEGIN
  IF NEW.good_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT id FROM OPENBILL_GOODS where id = NEW.good_id and unit = NEW.good_unit INTO result;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Good (#%) has wrong good unit (#%)', NEW.good_id, NEW.good_unit;
  END IF;

  INSERT INTO OPENBILL_GOODS_AVAILABILITIES AS GA (account_id, good_id, value)
    VALUES (NEW.from_account_id, NEW.good_id, - NEW.good_value)
    ON CONFLICT (account_id, good_id) DO UPDATE SET value = GA.value - NEW.good_value;

  INSERT INTO OPENBILL_GOODS_AVAILABILITIES AS GA (account_id, good_id, value)
    VALUES (NEW.to_account_id, NEW.good_id, NEW.good_value)
    ON CONFLICT (account_id, good_id) DO UPDATE SET value = GA.value + NEW.good_value;

  return NEW;
END

$process_transaction$ LANGUAGE plpgsql;

CREATE TRIGGER process_account_transaction_with_good
  AFTER INSERT ON OPENBILL_TRANSACTIONS FOR EACH ROW EXECUTE PROCEDURE process_account_transaction_with_good();

