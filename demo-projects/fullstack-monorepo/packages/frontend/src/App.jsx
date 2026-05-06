import { useState, useEffect } from "react";

function App() {
  const [items, setItems] = useState([]);

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_URL || "http://localhost:4000"}/api/items`)
      .then((r) => r.json())
      .then(setItems)
      .catch(console.error);
  }, []);

  return (
    <div>
      <h1>Fullstack Dashboard</h1>
      <ul>
        {items.map((item) => (
          <li key={item.id}>
            {item.name} — {item.status}
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
