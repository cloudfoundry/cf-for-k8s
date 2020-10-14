load("/testing_library.star", "assert_equals")
load("ingress.lib.yml", "ingress")

def test_ingress_adds_correct_host_for_every_hostname():
    result = ingress(
        "cupcake", ["meow.example.com", "woof.example.com"], "my-service", 8080
    )
    rules = result["spec"]["rules"]


    # We expect two rules with 2 hosts
    assert_equals(2, len(rules))

    # We expect the rules to have one host element for meow and another host for woof
    assert_equals("meow.example.com", rules[0]["host"])
    assert_equals("woof.example.com", rules[1]["host"])
end

def test_ingress_has_correct_tls_when_default_secretName_used():
    result = ingress(
        "pets", ["meow.example.com", "woof.example.com"], "my-service", 8080
    )

    # We expect one tls field with 2 hosts in it
    assert_equals(2, len(result["spec"]["tls"][0]["hosts"]))

    # We expect one tls entry with the default secretName if we don't assign one to secretName
    assert_equals("cf-system-cert", result["spec"]["tls"][0]["secretName"])
end

def test_ingress_has_correct_secretName_when_specified():
    result = ingress(
        "donut", ["brownie.example.com", "cupcake.example.com"], "my-service", 8080, tlsSecretName="my-secret-name"
    )

    # We expect one tls entry with the provided secretName if we assigned one
    assert_equals("my-secret-name", result["spec"]["tls"][0]["secretName"])
end

def test_ingress_has_default_namespace_when_not_specified():
    result = ingress(
        "pets", ["meow.example.com", "woof.example.com"], "my-service", 8080
    )

    assert_equals("cf-system", result["metadata"]["namespace"])
end

def test_ingress_has_correct_namespace_when_specified():
    result = ingress(
        "pets", ["meow.example.com", "woof.example.com"], "my-service", 8080, namespace="my-namespace"
    )

    assert_equals("my-namespace", result["metadata"]["namespace"])
end

test_ingress_adds_correct_host_for_every_hostname()
test_ingress_has_correct_secretName_when_specified()
test_ingress_has_correct_tls_when_default_secretName_used()
test_ingress_has_default_namespace_when_not_specified()
test_ingress_has_correct_namespace_when_specified()
