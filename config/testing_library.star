load("@ytt:assert", "assert")

def assert_equals(expected, actual):
  if actual != expected:
    assert.fail("Expected %s, but found %s" % (expected, actual))
  end
end

