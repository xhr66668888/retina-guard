export class ScreenUsageTracker {
  private accumulatedMs: number = 0;
  private lastResumeTime: number = 0;
  private excludedPackages: string[] = [];
  private _screenOn: boolean = true;
  private paused: boolean = false;

  start(initialMs: number, excluded: string[]): void {
    this.accumulatedMs = initialMs;
    this.excludedPackages = excluded;
    this._screenOn = true;
    this.lastResumeTime = Date.now();
    this.paused = false;
  }

  stop(): number {
    this.flush();
    return this.accumulatedMs;
  }

  getAccumulatedMs(): number {
    this.flush();
    return this.accumulatedMs;
  }

  updateExcluded(excluded: string[]): void {
    this.excludedPackages = excluded;
  }

  tick(): void {
    if (!this._screenOn) return;
    const now = Date.now();
    this.accumulatedMs += (now - this.lastResumeTime);
    this.lastResumeTime = now;
  }

  private flush(): void {
    if (!this._screenOn || this.lastResumeTime === 0) return;
    const now = Date.now();
    this.accumulatedMs += (now - this.lastResumeTime);
    this.lastResumeTime = now;
  }
}
