m=Menu.find(6804); m.update!(title: m.title.sub('О стыдливости','О целомудрии')); puts m.title
Page.where(id:[631,369]).each{|q| puts q.path, q.body.scan(/href="[^"]*wvx9_[^"]*"/).map{|h| URI.decode_www_form_component(h)}.inspect}
