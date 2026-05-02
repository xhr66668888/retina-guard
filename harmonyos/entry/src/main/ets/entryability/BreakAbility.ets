import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class BreakAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/BreakPage', (err) => {
      if (err.code) return;
    });
    try {
      windowStage.getMainWindow().then((win) => {
        win.setWindowLayoutFullScreen(true);
      });
    } catch (e) { /* ignore */ }
  }
}
