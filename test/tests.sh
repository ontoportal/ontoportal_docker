# Here you write the tests
# And run them using test/run_tests.sh
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../src:$PATH"
    ./ontoportal clean -f
}

@test "Running and Stopping API" {
  run ./ontoportal start api 
  assert_output --partial "[+] API is up and running!"
  refute_output --partial 'error'
  refute_output --partial 'ERROR'

  ./ontoportal stop api
  run docker compose -f docker-compose_api.yml ps
  assert_output "NAME      IMAGE     COMMAND   SERVICE   CREATED   STATUS    PORTS"
}

@test "Running and Stopping UI" {

  ./ontoportal start api 

  run ./ontoportal start ui

  assert_output --partial "[+] UI is up and running!"
  refute_output --partial 'error'
  refute_output --partial 'ERROR'

   ./ontoportal stop ui

  run docker compose -f docker-compose_ui.yml ps
  assert_output "NAME      IMAGE     COMMAND   SERVICE   CREATED   STATUS    PORTS"
}
