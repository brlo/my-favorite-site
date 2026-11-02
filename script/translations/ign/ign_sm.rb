p=Page.find(373); puts p.references.to_s.scan(/<li>.*?<\/li>/m)[6]; i=p.body.index("[7]"); puts p.body[i-700,900]
g=Page.find(387).body; puts "--grc ch8:"; puts g[/<h2>8<\/h2>.*?<\/p>/m]
e=Page.find(380).body; puts "--en ch8:"; puts e[/<h2>8<\/h2>.*?<h2>/m]
