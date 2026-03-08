# Phaser 3 Patterns Reference (3.90+)

Stack: Phaser 3.90+, TypeScript, Capacitor (Android), AdMob. Existing JS projects should be migrated to TS.

---

## TypeScript Setup

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "lib": ["ES2020", "DOM"]
  }
}
```

```bash
npm install phaser
npm install --save-dev typescript @types/node vite
```

**Vite config:**
```typescript
// vite.config.ts
import { defineConfig } from 'vite'

export default defineConfig({
  base: './',
  build: {
    rollupOptions: {
      output: { manualChunks: { phaser: ['phaser'] } }
    }
  }
})
```

---

## Scene Pattern (TypeScript)

```typescript
// Always extend Phaser.Scene with typed properties
export class GameScene extends Phaser.Scene {
  private player!: Phaser.Physics.Arcade.Sprite
  private enemies!: Phaser.Physics.Arcade.Group
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys

  constructor() {
    super({ key: 'GameScene' })
  }

  preload(): void {
    this.load.atlas('player', 'assets/player.png', 'assets/player.json')
    this.load.image('tileset', 'assets/tileset.png')
  }

  create(): void {
    this.cursors = this.input.keyboard!.createCursorKeys()
    this.player = this.physics.add.sprite(100, 100, 'player')
    this.enemies = this.physics.add.group({ classType: Enemy, maxSize: 20 })

    // Clean up on scene shutdown — always
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, this.shutdown, this)
  }

  update(_time: number, _delta: number): void {
    this.handleInput()
  }

  private handleInput(): void {
    if (this.cursors.left.isDown) {
      this.player.setVelocityX(-160)
    } else if (this.cursors.right.isDown) {
      this.player.setVelocityX(160)
    } else {
      this.player.setVelocityX(0)
    }
  }

  private shutdown(): void {
    // Remove listeners, clear timers, destroy non-Phaser objects
  }
}
```

---

## Scene Lifecycle Order

```
constructor → init(data) → preload → create → update (loop) → shutdown → destroy
```

- `init` — receives data passed from previous scene; set instance vars here
- `preload` — load assets; only runs if assets not already cached
- `create` — build the scene; safe to reference all loaded assets
- `update(time, delta)` — game loop; use `delta` for frame-rate-independent movement
- `shutdown` — scene stopped but not destroyed; clean up listeners/timers here
- `destroy` — scene removed entirely

---

## Scene Communication

```typescript
// Pass data to next scene
this.scene.start('GameScene', { level: 2, score: this.score })

// Receive in target scene
init(data: { level: number; score: number }): void {
  this.level = data.level
  this.score = data.score
}

// Emit events across scenes via registry (global store)
this.registry.set('score', 100)
this.registry.events.on('changedata-score', (_: any, value: number) => {
  this.scoreText.setText(`Score: ${value}`)
})

// Run scenes in parallel (e.g. HUD over game)
this.scene.launch('HUDScene')
this.scene.bringToTop('HUDScene')
```

---

## Object Pooling

Never create game objects in `update()`. Use groups with `maxSize` for pooling.

```typescript
// Good: pool in create()
this.bullets = this.physics.add.group({
  classType: Bullet,
  maxSize: 30,
  runChildUpdate: true,
})

// Fire from pool — no new allocation
fire(x: number, y: number): void {
  const bullet = this.bullets.get(x, y) as Bullet | null
  if (bullet) {
    bullet.fire(x, y)
  }
}

// Bullet class — returns itself to pool when off-screen
export class Bullet extends Phaser.Physics.Arcade.Image {
  fire(x: number, y: number): void {
    this.setActive(true).setVisible(true).setPosition(x, y)
    this.setVelocityY(-400)
  }

  preUpdate(time: number, delta: number): void {
    super.preUpdate(time, delta)
    if (this.y < -32) {
      this.setActive(false).setVisible(false)
    }
  }
}
```

---

## Asset Management

**Always use a dedicated preload scene:**
```typescript
export class PreloadScene extends Phaser.Scene {
  constructor() { super({ key: 'PreloadScene' }) }

  preload(): void {
    // Progress bar
    const bar = this.add.graphics()
    this.load.on('progress', (value: number) => {
      bar.clear().fillStyle(0xffffff).fillRect(0, 0, 800 * value, 4)
    })

    // Use texture atlases — not individual images
    this.load.atlas('sprites', 'assets/sprites.png', 'assets/sprites.json')
    this.load.tilemapTiledJSON('map', 'assets/map.json')
    this.load.audio('music', ['assets/music.ogg', 'assets/music.mp3'])
  }

  create(): void {
    this.scene.start('MenuScene')
  }
}
```

**Asset rules:**
- Use texture atlases (TexturePacker) over individual image files
- Always provide OGG + MP3 fallback for audio
- Load tilemaps via `tilemapTiledJSON` — not manual parsing
- Cache keys must be unique across all scenes

---

## Physics Patterns (Arcade)

```typescript
// Typed collider
this.physics.add.collider(
  this.player,
  this.platforms,
  undefined,
  undefined,
  this
)

// Overlap with callback
this.physics.add.overlap(
  this.player,
  this.coins,
  this.collectCoin,
  undefined,
  this
)

private collectCoin(
  player: Phaser.Types.Physics.Arcade.GameObjectWithBody,
  coin: Phaser.Types.Physics.Arcade.GameObjectWithBody
): void {
  (coin as Phaser.Physics.Arcade.Image).disableBody(true, true)
  this.score += 10
}

// Frame-rate independent movement — always use delta
update(_time: number, delta: number): void {
  const speed = 200 * (delta / 1000)  // pixels per second
  this.player.x += speed
}
```

---

## Animation Patterns

```typescript
// Define in create() — check if already exists to avoid duplicate warnings
create(): void {
  if (!this.anims.exists('walk')) {
    this.anims.create({
      key: 'walk',
      frames: this.anims.generateFrameNames('player', {
        prefix: 'walk_',
        start: 0,
        end: 7,
        zeroPad: 2,
      }),
      frameRate: 12,
      repeat: -1,
    })
  }
}
```

---

## Separating Logic from Phaser (Testability)

Phaser requires a DOM/canvas — it cannot run in Node.js tests. Keep game logic in plain classes.

```typescript
// Bad: logic inside a Scene method — untestable
update(): void {
  if (this.player.x > 800) {
    this.score += this.level * 10
    this.lives--
  }
}

// Good: pure logic class — fully testable with Vitest/Jest
export class ScoreSystem {
  score = 0
  lives = 3

  onPlayerExit(level: number): void {
    this.score += level * 10
    this.lives--
  }

  isGameOver(): boolean {
    return this.lives <= 0
  }
}

// Scene delegates to it
update(): void {
  if (this.player.x > 800) {
    this.scoreSystem.onPlayerExit(this.level)
    if (this.scoreSystem.isGameOver()) {
      this.scene.start('GameOverScene')
    }
  }
}

// Test (Vitest — no Phaser needed)
it('deducts a life on exit', () => {
  const system = new ScoreSystem()
  system.onPlayerExit(2)
  expect(system.lives).toBe(2)
  expect(system.score).toBe(20)
})
```

---

## JS → TypeScript Migration

**Priority order:**
1. Rename `.js` → `.ts` one file at a time
2. Start with `"strict": false`, enable rules incrementally
3. Type game object properties explicitly — avoid `any`
4. Replace `this.scene.get('key')` casts with typed scene references

```typescript
// Bad: JS habit
let player
create() {
  player = this.physics.add.sprite(100, 100, 'player')
}

// Good: TS — typed, non-null asserted on declaration
private player!: Phaser.Physics.Arcade.Sprite
create(): void {
  this.player = this.physics.add.sprite(100, 100, 'player')
}

// Typed scene data interface
interface GameSceneData {
  level: number
  score: number
}

export class GameScene extends Phaser.Scene {
  private data!: GameSceneData

  init(data: GameSceneData): void {
    this.data = data
  }
}
```

**Migration steps for a JS project:**
1. Add `tsconfig.json` with `"allowJs": true, "checkJs": false` — compile without errors
2. Rename entry files to `.ts`; leave others as `.js` temporarily
3. Add `"checkJs": true` per file using `// @ts-check` at top
4. Rename remaining files to `.ts` and fix type errors
5. Enable `"strict": true` once all files are `.ts`

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| Creating objects in `update()` | Create in `create()`, pool with `group.get()` |
| `this.add.image()` for every frame | Use texture atlases; pack with TexturePacker |
| Not cleaning up event listeners | `this.events.once(SHUTDOWN, this.shutdown, this)` |
| `scene.get('Key') as any` | Type the scene reference explicitly |
| Game logic inside Scene methods | Extract to plain classes for testability |
| Using `setInterval`/`setTimeout` | Use `this.time.addEvent()` — pauses with scene |
| Hardcoded pixel positions | Use scene width/height: `this.scale.width` |
| Loading assets in `create()` | Always load in `preload()` or PreloadScene |
| Separate image files per sprite | Use texture atlases |
| Mutating physics body directly in `update()` loop without checking active state | Check `gameObject.active` before operating on pooled objects |

---

## Android / Capacitor Setup

```bash
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init
npx cap add android
```

```typescript
// capacitor.config.ts
import { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'com.yourname.gamename',
  appName: 'Game Name',
  webDir: 'dist',
  android: {
    backgroundColor: '#000000',
  },
  plugins: {
    AdMob: {
      appId: 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX', // your Android app ID
    },
  },
}

export default config
```

**Build → deploy pipeline:**
```bash
npm run build          # vite build → dist/
npx cap sync           # copy dist/ to android/app/src/main/assets/public
npx cap open android   # open Android Studio for signing + release
```

---

## Phaser Scale for Mobile

```typescript
// main.ts — responsive config for portrait/landscape mobile
const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: 720,
  height: 1280,   // portrait default — swap for landscape
  backgroundColor: '#000000',
  scale: {
    mode: Phaser.Scale.FIT,           // fit within screen, maintain ratio
    autoCenter: Phaser.Scale.CENTER_BOTH,
    parent: 'game',
  },
  physics: { default: 'arcade', arcade: { gravity: { x: 0, y: 300 }, debug: false } },
  scene: [BootScene, PreloadScene, MenuScene, GameScene],
}
```

**Orientation lock (Android):** set in `android/app/src/main/AndroidManifest.xml`:
```xml
android:screenOrientation="portrait"   <!-- or "landscape" -->
```

---

## Mobile Input (Touch)

Do not rely on keyboard input — use Phaser pointer events.

```typescript
create(): void {
  // Tap / touch
  this.input.on('pointerdown', (pointer: Phaser.Input.Pointer) => {
    this.handleTap(pointer.x, pointer.y)
  })

  // Swipe detection
  let startX = 0
  this.input.on('pointerdown', (p: Phaser.Input.Pointer) => { startX = p.x })
  this.input.on('pointerup', (p: Phaser.Input.Pointer) => {
    const delta = p.x - startX
    if (Math.abs(delta) > 50) {
      this.handleSwipe(delta > 0 ? 'right' : 'left')
    }
  })

  // Virtual joystick — use rexvirtualjoystick plugin if needed
}
```

---

## AdMob Integration

```bash
npm install @capacitor-community/admob
npx cap sync
```

**Centralise all ad logic in a single service — never call AdMob directly from scenes:**

```typescript
// src/services/AdService.ts
import { AdMob, BannerAdOptions, InterstitialAdOptions, RewardAdOptions } from '@capacitor-community/admob'

const IDS = {
  banner:       'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
  interstitial: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
  rewarded:     'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
  // Test IDs for development:
  // banner:       'ca-app-pub-3940256099942544/6300978111',
  // interstitial: 'ca-app-pub-3940256099942544/1033173712',
  // rewarded:     'ca-app-pub-3940256099942544/5224354917',
}

export class AdService {
  static async init(): Promise<void> {
    await AdMob.initialize({ testingDevices: [], initializeForTesting: false })
  }

  static async showBanner(): Promise<void> {
    const options: BannerAdOptions = {
      adId: IDS.banner,
      adSize: AdMobBannerSize.BANNER,
      position: AdMobBannerPosition.BOTTOM_CENTER,
      margin: 0,
    }
    await AdMob.showBanner(options)
  }

  static async hideBanner(): Promise<void> {
    await AdMob.hideBanner()
  }

  static async showInterstitial(): Promise<void> {
    const options: InterstitialAdOptions = { adId: IDS.interstitial }
    await AdMob.prepareInterstitial(options)
    await AdMob.showInterstitial()
  }

  static async showRewarded(): Promise<{ rewarded: boolean }> {
    const options: RewardAdOptions = { adId: IDS.rewarded }
    await AdMob.prepareRewardVideoAd(options)
    return new Promise((resolve) => {
      AdMob.addListener(AdMobRewardItem, (reward) => resolve({ rewarded: true }))
      AdMob.showRewardVideoAd().catch(() => resolve({ rewarded: false }))
    })
  }
}
```

**Using AdService from scenes:**
```typescript
// In GameOverScene
async create(): Promise<void> {
  // Show interstitial between rounds
  await AdService.showInterstitial()

  // Rewarded ad for continue
  this.continueButton.on('pointerdown', async () => {
    const { rewarded } = await AdService.showRewarded()
    if (rewarded) {
      this.scene.start('GameScene', { continued: true })
    }
  })
}
```

**AdMob rules:**
- Always use test IDs during development — never ship with test IDs
- Never show ads during active gameplay — only between rounds/levels or on game over
- Rewarded ads must be genuinely optional — never gate core gameplay behind them (Play Store policy)
- Initialise AdMob in the Boot/Preload scene before any scene shows an ad
- Never call AdMob APIs on web build — guard with `Capacitor.isNativePlatform()`

```typescript
import { Capacitor } from '@capacitor/core'

if (Capacitor.isNativePlatform()) {
  await AdService.init()
}
```

---

## Mobile Performance

- **Target 60fps** on mid-range Android (Snapdragon 665 class)
- Use `Phaser.AUTO` renderer — Phaser picks WebGL over Canvas automatically
- Texture atlases are critical on mobile — individual images cause excessive draw calls
- Audio: provide OGG only for Android (no MP3 patent issues in modern Android)
- Disable physics debug in production: `debug: false`
- Keep active game objects low — pool aggressively (`maxSize` on groups)
- Avoid `update()` work when game is paused: listen to `Phaser.Core.Events.BLUR`

```typescript
// Pause game when app goes to background (Capacitor)
import { App } from '@capacitor/app'

App.addListener('appStateChange', ({ isActive }) => {
  if (isActive) {
    this.game.resume()
  } else {
    this.game.pause()
    AdService.hideBanner()
  }
})
```

---

## Android Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| Keyboard input in mobile game | Use pointer/touch events only |
| Calling `AdMob` directly from scenes | Route through `AdService` singleton |
| Using real Ad IDs during development | Use AdMob test IDs during dev |
| Showing ads mid-gameplay | Show only on game over / between levels |
| Not guarding AdMob on web build | Wrap with `Capacitor.isNativePlatform()` |
| Fixed pixel layout at 1920×1080 | Use `Phaser.Scale.FIT` + `autoCenter` |
| MP3 for all audio | OGG for Android; provide MP3 only as web fallback |
| Loading assets on every scene start | Use PreloadScene once; Phaser caches loaded assets |
| No app background handling | Pause game + hide banner on `appStateChange` |

---

## References

| Topic | Source |
|-------|--------|
| Full API | https://photonstorm.github.io/phaser3-docs/ |
| Examples | https://phaser.io/examples |
| TypeScript template | https://github.com/photonstorm/phaser3-typescript-project-template |
| Capacitor AdMob plugin | https://github.com/capacitor-community/admob |
| AdMob test IDs | https://developers.google.com/admob/android/test-ads |
