require! <[
  mocha
  assert
]>

$it = it

describe 'sample test', ->
  $it 'should report true', ->
    assert.equal 1, 1
