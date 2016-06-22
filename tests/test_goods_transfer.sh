#!/usr/bin/env bash

. ./tests/init.sh && \
. ./tests/2accounts.sh && \

./tests/assert_result.sh "insert into OPENBILL_GOODS (title, unit) values ('Boxes', 'boxes');" "INSERT 0 1" && \
./tests/assert_result.sh "insert into OPENBILL_GOODS (title, unit) values ('Bottles', 'Bottles');" "INSERT 0 1" && \

./tests/assert_result.sh "insert into OPENBILL_TRANSACTIONS (amount_cents, amount_currency, from_account_id, to_account_id, key, details, good_id, good_unit, good_value) values (100, 'USD', 1, 2, 'gid://order1', 'test', 1, 'boxes', 12.4);" "INSERT 0 1" && \

./tests/assert_value.sh "select id, good_id, value from OPENBILL_GOODS_AVAILABILITIES" "1|1|-12.4
2|1|12.4"
