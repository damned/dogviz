require_relative '../lib/webvis'

def describe_tw_com(sys)
  website = sys.thing('website')
  sys.user('visitor').points_to website
end

def output(sys, name)
  sys.output(dot: "#{name}-generated.dot")
  sys.output(png: "#{name}-generated.png")
  sys.output(svg: "#{name}-generated.svg")
end

include Webvis

render_hints = {
    splines: false
}
sys = WebsiteSystem.new 'website', render_hints

describe_tw_com sys
output sys, 'website'
