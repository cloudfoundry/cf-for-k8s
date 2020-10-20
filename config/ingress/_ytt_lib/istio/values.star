load("@ytt:data", ytt_data="data")
load("@ytt:yaml", "yaml")
load("@ytt:struct", "struct")
load("@ytt:assert", "assert")


#! data.values.values is string with YAML of data.values
#! We decode YAML into dictonary, then we convert dictonary
#! to structure so we can access values without using [] indexer.
#! So instead of data.values["system_namespace"] we will use
#! data.values.system_namespace
data = struct.encode({ "values": yaml.decode(ytt_data.values.values)})
