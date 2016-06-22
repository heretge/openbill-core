#!/usr/bin/env bash

. ./tests/init.sh && \
. ./tests/2accounts.sh && \

./tests/assert_result.sh "insert into OPENBILL_GOODS (title, unit) values ('Boxes', 'boxes');" "INSERT 0 1" && \
./tests/assert_result.sh "insert into OPENBILL_GOODS (title, unit) values ('Bottles', 'Bottles');" "INSERT 0 1" && \

./tests/assert_result.sh "insert into OPENBILL_TRANSACTIONS (amount_cents, amount_currency, from_account_id, to_account_id, key, details, good_id, good_unit, good_value) values (100, 'USD', 1, 2, 'gid://order1', 'test', 1, 'boxes_mistake', 1);" "ERROR:  Good (#1) has wrong good unit (#boxes_mistake)" && \

./tests/assert_value.sh "select count(*) from OPENBILL_GOODS_AVAILABILITIES" "0" && \
./tests/assert_value.sh 'select count(*) from OPENBILL_TRANSACTIONS ' '0' && \
./tests/assert_value.sh 'select amount_cents from OPENBILL_ACCOUNTS  where id=1' '0' && \
./tests/assert_value.sh 'select amount_cents from OPENBILL_ACCOUNTS  where id=2' '0'
