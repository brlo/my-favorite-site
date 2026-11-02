q=Verse.where(tr_code:'ge-sch').where("text ~ '[ぁ-んァ-ン一-龥]'"); puts q.count; puts q.group(:book).count.inspect
