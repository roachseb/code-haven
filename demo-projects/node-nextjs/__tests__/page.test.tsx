import { render, screen } from "@testing-library/react";
import Home from "../src/app/page";

describe("Home", () => {
  it("renders the heading", () => {
    render(<Home />);
    expect(screen.getByText("Next.js Dashboard")).toBeInTheDocument();
  });
});
