struct NamedTuple
  def []?(key : String)
    fetch(key) { nil }
  end

  def [](key : String)
    fetch(key) { raise KeyError.new "Missing named tuple key: #{key.inspect}" }
  end

  def fetch(key : String, &block)
    {% for key in T %}
      return self[{{key.symbolize}}] if {{key.stringify}} == key
    {% end %}
    yield
  end
end
