Page.where(id:[631,369]).each{|q| s=q.body; puts s.scan(/.{0,5}#HH-10"/).size}
