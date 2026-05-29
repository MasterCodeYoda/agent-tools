// Article card — PLANTED VIOLATIONS for evolve scenario testing.

interface Article {
  title: string;
  summary: string;
  imageUrl: string;
  href: string;
}

export function ArticleCard({ article }: { article: Article }) {
  return (
    <div className="article-card" style={{ border: "1px solid #eee", borderRadius: "8px" }}>
      {/* VIOLATION VDV-05: No explicit width/height on image
          Content below shifts when the image loads */}
      <img src={article.imageUrl} style={{ width: "100%" }} />

      <div style={{ padding: "16px" }}>
        <h3>{article.title}</h3>
        <p>{article.summary}</p>

        {/* VIOLATION VDV-03: Non-descriptive link text
            Screen readers announce "click here" for every card */}
        <a href={article.href}>click here</a>
        {" to "}
        <a href={`${article.href}#full`}>read more</a>
      </div>
    </div>
  );
}

// GOOD: Descriptive link text for comparison
export function ArticleCardAccessible({ article }: { article: Article }) {
  return (
    <div className="article-card">
      <img src={article.imageUrl} width={600} height={400} alt={article.title} />
      <div>
        <h3>{article.title}</h3>
        <p>{article.summary}</p>
        <a href={article.href}>Read full article: {article.title}</a>
      </div>
    </div>
  );
}
