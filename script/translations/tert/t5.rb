Page.where(lang:'ru',path:%w[тертуллиан иконы-почитают]).each{|q| [q.body,q.body_rendered.to_s].each{|s| puts q.path, URI.decode_www_form_component(s[/href="[^"]*wvx9_[^"]*"/].to_s)}}
