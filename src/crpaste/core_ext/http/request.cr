class HTTP::Request
  def path
    uri.path.not_nil!
  end
end
