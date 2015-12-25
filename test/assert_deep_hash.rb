require 'hashdiff'
require 'erb'

module AssertDeepHash

  def assert_deep_hash(expected, actual, msg = nil)
    differences = HashDiff.diff(expected, actual)

    msg = message(msg) do
      hash_diff = diff(expected, actual)
      rb_balls = ERB.new(<<-ERB)
        #{hash_diff}
        Differences:
          <% differences.each do |difference| %>
          <%= difference.inspect %>
          <% end %>
      ERB

      rb_balls.result(binding)
    end

    assert differences == [], msg
  end
end
