import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

import { API_ENDPOINTS } from "@/config/apiConfig";
import { Difficulty, quizHistory, quizSession, uploadImageAndGenerateQuiz } from "@/api/quizApi";

describe("quizService simple tests", () => {
  const token = "my-token";

  beforeEach(() => {
    vi.restoreAllMocks();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ---------- uploadImageAndGenerateQuiz ----------
  it("uploadImageAndGenerateQuiz returns data on success", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ quizSessionId: 1 }),
    }));

    const file = new File(["dummy"], "test.png", { type: "image/png" });

    const result = await uploadImageAndGenerateQuiz(file, Difficulty.Easy, token);
    expect(result).toEqual({ quizSessionId: 1 });
  });

  it("uploadImageAndGenerateQuiz throws error on failure", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: false }));

    const file = new File(["dummy"], "test.png", { type: "image/png" });

    await expect(uploadImageAndGenerateQuiz(file, Difficulty.Easy, token))
      .rejects.toThrow("Failed to generate quiz");
  });

  // ---------- quizHistory ----------
  it("quizHistory returns data on success", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
      ok: true,
      json: async () => [{ quizSessionId: 1, createdAt: "2026-03-09", questionCount: 5, difficulty: Difficulty.Easy }],
    }));

    const result = await quizHistory(token);
    expect(result.length).toBe(1);
    expect(result[0].quizSessionId).toBe(1);
  });

  it("quizHistory throws error on failure", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: false }));

    await expect(quizHistory(token)).rejects.toThrow("Failed to get quiz history");
  });

  // ---------- quizSession ----------
  it("quizSession returns data on success", async () => {
    const id = 123;
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ quizSessionId: id, questions: [] }),
    }));

    const result = await quizSession(id, token);
    expect(result.quizSessionId).toBe(id);
  });

  it("quizSession throws error on failure", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: false }));

    await expect(quizSession(123, token)).rejects.toThrow("Failed to get quiz session");
  });
});
