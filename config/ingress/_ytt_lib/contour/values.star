load("@ytt:data", ytt_data="data")
load("@ytt:yaml", "yaml")
load("@ytt:struct", "struct")
load("@ytt:assert", "assert")


#! data.values.values is string with YAML of data.values
#! We decode YAML into dictonary, then we convert dictonary
#! to structure so we can access values without using [] indexer.
#! So instead of data.values["system_namespace"] we will use
#! data.values.system_namespace
data_values_dict = { "values": yaml.decode(ytt_data.values.values) }

#! In addition to values passed from outsite we also have internal values.
#! We want to merge these values into our result structure, so all data values
#! can be accessed through one object. Have fun!
for key in dir(ytt_data.values):
  if key != "values":
    data_values_dict["values"][key] = getattr(ytt_data.values, key)
  end
end

data = struct.encode(data_values_dict)
