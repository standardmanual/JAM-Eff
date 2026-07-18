import SwiftUI

// MARK: - ShaderThumbnailView

struct ShaderThumbnailView: View {
    let effect: ShaderEffect
    var cornerRadius: CGFloat = 8

    var body: some View {
        Canvas { ctx, size in
            drawBackground(ctx: &ctx, size: size)
            drawPattern(ctx: &ctx, size: size)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: Background

    private func drawBackground(ctx: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let colors = effect.thumbnailColors
        ctx.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: colors),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )
    }

    // MARK: Pattern

    private func drawPattern(ctx: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height

        switch effect {

        // ── Dot grid patterns ──
        case .halftoneDots:
            let r = w / 12
            for row in 0..<4 { for col in 0..<4 {
                let x = w * CGFloat(col + 1) / 5
                let y = h * CGFloat(row + 1) / 5
                ctx.fill(ellipse(cx: x, cy: y, r: r), with: .color(.white.opacity(0.75)))
            }}

        case .dotGrid:
            let gap = w / 5, r: CGFloat = 3
            for row in 0...4 { for col in 0...4 {
                let x = CGFloat(col) * gap + gap / 2
                let y = CGFloat(row) * gap + gap / 2
                ctx.fill(ellipse(cx: x, cy: y, r: r), with: .color(.white.opacity(0.8)))
            }}

        case .halftoneCMYK:
            let r = w * 0.26
            for (cx, cy, col): (CGFloat, CGFloat, Color) in [
                (w * 0.38, h * 0.38, .cyan), (w * 0.62, h * 0.38, .pink), (w * 0.5, h * 0.65, .yellow)
            ] {
                ctx.fill(ellipse(cx: cx, cy: cy, r: r), with: .color(col.opacity(0.65)))
            }

        // ── Line patterns ──
        case .flutedGlass:
            let count = 7
            let lw = w / CGFloat(count * 2)
            for i in 0..<count {
                let x = w * CGFloat(i) / CGFloat(count) + lw / 2
                ctx.stroke(vLine(x: x, h: h), with: .color(.white.opacity(0.45)), lineWidth: lw * 0.8)
            }

        case .paperTexture:
            for i in 0..<10 {
                let y = h * CGFloat(i) / 10 + h / 20
                let jitter = CGFloat((i * 7) % 5 - 2)
                ctx.stroke(hLine(y: y, offset: jitter, w: w), with: .color(Color.white.opacity(0.2)), lineWidth: 1)
            }

        case .warp:
            for (i, col): (Int, Color) in [(0, .pink), (1, .blue), (2, .yellow)] {
                var p = Path()
                let yBase = h * CGFloat(i + 1) / 4
                p.move(to: CGPoint(x: 0, y: yBase))
                for x in stride(from: 0.0, to: w, by: 2.0) {
                    p.addLine(to: CGPoint(x: x, y: yBase + 10 * sin(x / w * .pi * 2 + Double(i))))
                }
                ctx.stroke(p, with: .color(col.opacity(0.75)), lineWidth: 5)
            }

        // ── Wave patterns ──
        case .water:
            for i in 0..<4 {
                let yBase = h * CGFloat(i + 1) / 5
                ctx.stroke(wavePath(yBase: yBase, w: w, amp: 6, freq: 3, phase: Double(i)), with: .color(.white.opacity(0.5)), lineWidth: 1.5)
            }

        case .waves:
            for i in 0..<5 {
                let yBase = h * CGFloat(i) / 4
                ctx.stroke(wavePath(yBase: yBase, w: w, amp: 8, freq: 2, phase: Double(i) * 0.5), with: .color(.white.opacity(0.4)), lineWidth: 1.5)
            }

        // ── Checkerboard / dithering ──
        case .imageDithering, .dithering:
            let cell = w / 7
            for row in 0..<7 { for col in 0..<7 {
                if (row + col) % 2 == 0 {
                    ctx.fill(Path(CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)),
                             with: .color(.white.opacity(0.5)))
                }
            }}

        // ── Orbit / concentric ──
        case .dotOrbit:
            let cx = w / 2, cy = h / 2
            for ring in 1...3 {
                let r = CGFloat(ring) * w / 8
                ctx.stroke(ringPath(cx: cx, cy: cy, r: r), with: .color(.white.opacity(0.3)), lineWidth: 1)
                let angle = Double(ring) * 1.2
                ctx.fill(ellipse(cx: cx + CGFloat(cos(angle)) * r, cy: cy + CGFloat(sin(angle)) * r, r: 3.5),
                         with: .color(.white.opacity(0.9)))
            }

        case .pulsingBorder:
            for i in 0..<3 {
                let inset = CGFloat(i) * 6 + 4
                let rect = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
                ctx.stroke(Path(roundedRect: rect, cornerRadius: 5),
                           with: .color(Color.purple.opacity(0.8 - Double(i) * 0.2)), lineWidth: 2)
            }

        case .smokeRing:
            let r = min(w, h) * 0.34
            ctx.stroke(ringPath(cx: w / 2, cy: h / 2, r: r), with: .color(.orange.opacity(0.8)), lineWidth: 6)

        // ── Spiral ──
        case .spiral:
            var p = Path()
            let cx = w / 2, cy = h / 2, maxR = min(w, h) * 0.44
            for (idx, t) in stride(from: 0.0, to: 6 * Double.pi, by: 0.15).enumerated() {
                let r = maxR * t / (6 * Double.pi)
                let pt = CGPoint(x: cx + CGFloat(cos(t)) * r, y: cy + CGFloat(sin(t)) * r)
                if idx == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            ctx.stroke(p, with: .color(.white.opacity(0.8)), lineWidth: 1.5)

        case .swirl:
            for ring in 1...4 {
                let r = CGFloat(ring) * min(w, h) / 10
                let cx = w / 2, cy = h / 2
                var p = Path()
                for (idx, t) in stride(from: 0.0, to: 2 * Double.pi, by: 0.15).enumerated() {
                    let pt = CGPoint(x: cx + CGFloat(cos(t + Double(ring))) * r,
                                     y: cy + CGFloat(sin(t + Double(ring))) * r)
                    if idx == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
                ctx.stroke(p, with: .color(.white.opacity(0.45)), lineWidth: 1.5)
            }

        // ── Radial / god rays ──
        case .godRays:
            let cx = w / 2, cy = h / 2
            for i in 0..<9 {
                let angle = Double(i) / 9 * 2 * Double.pi
                var p = Path()
                p.move(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(x: cx + CGFloat(cos(angle)) * w * 0.6,
                                      y: cy + CGFloat(sin(angle)) * h * 0.6))
                ctx.stroke(p, with: .color(Color.yellow.opacity(0.4)), lineWidth: CGFloat(3 - i % 3))
            }

        case .staticRadialGradient:
            let cx = w / 2, cy = h / 2
            for i in 0..<6 {
                let angle = Double(i) / 6 * 2 * Double.pi
                var p = Path()
                p.move(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(x: cx + CGFloat(cos(angle)) * w * 0.5,
                                      y: cy + CGFloat(sin(angle)) * h * 0.5))
                ctx.stroke(p, with: .color(.white.opacity(0.35)), lineWidth: 2)
            }

        // ── Mesh grid ──
        case .meshGradient, .staticMeshGradient:
            for i in 1..<3 {
                let x = w * CGFloat(i) / 3, y = h * CGFloat(i) / 3
                ctx.stroke(vLine(x: x, h: h), with: .color(.white.opacity(0.3)), lineWidth: 1)
                ctx.stroke(hLine(y: y, offset: 0, w: w), with: .color(.white.opacity(0.3)), lineWidth: 1)
            }

        // ── Noise patterns ──
        case .perlinNoise, .simplexNoise:
            for i in 0..<6 {
                var p = Path()
                let yBase = h * CGFloat(i) / 5
                p.move(to: CGPoint(x: 0, y: yBase))
                for x in stride(from: 0.0, to: w, by: 3.0) {
                    p.addLine(to: CGPoint(x: x, y: yBase + 12 * sin(x / 18 + Double(i) * 0.8)))
                }
                ctx.stroke(p, with: .color(.white.opacity(0.3)), lineWidth: 2)
            }

        case .neuroNoise:
            var p = Path()
            let pts: [(CGFloat, CGFloat)] = [(0.3,0.4),(0.5,0.2),(0.72,0.4),(0.8,0.62),(0.5,0.82),(0.2,0.6)]
            p.move(to: CGPoint(x: pts[0].0 * w, y: pts[0].1 * h))
            for pt in pts.dropFirst() { p.addLine(to: CGPoint(x: pt.0 * w, y: pt.1 * h)) }
            p.closeSubpath()
            ctx.stroke(p, with: .color(Color.purple.opacity(0.7)), lineWidth: 2.5)

        case .grainGradient:
            let xs: [CGFloat] = [0.12,0.28,0.45,0.6,0.75,0.88,0.2,0.55,0.7,0.38,0.9,0.15]
            let ys: [CGFloat] = [0.3,0.6,0.2,0.75,0.4,0.15,0.85,0.5,0.65,0.9,0.45,0.7]
            for i in 0..<min(xs.count, ys.count) {
                ctx.fill(ellipse(cx: xs[i] * w, cy: ys[i] * h, r: 1.5), with: .color(.white.opacity(0.75)))
            }

        // ── Cells ──
        case .voronoi:
            let seeds: [(CGFloat, CGFloat)] = [(0.25,0.3),(0.7,0.2),(0.5,0.6),(0.2,0.72),(0.8,0.75)]
            for (px, py) in seeds {
                ctx.fill(ellipse(cx: px * w, cy: py * h, r: 5), with: .color(.white.opacity(0.5)))
            }
            // draw approximated cell lines
            var p = Path()
            p.move(to: CGPoint(x: 0.475 * w, y: 0))
            p.addLine(to: CGPoint(x: 0.475 * w, y: h))
            p.move(to: CGPoint(x: 0, y: 0.5 * h))
            p.addLine(to: CGPoint(x: w, y: 0.5 * h))
            ctx.stroke(p, with: .color(.white.opacity(0.3)), lineWidth: 1)

        // ── Blobs ──
        case .metaballs:
            for (bx, by, br): (CGFloat, CGFloat, CGFloat) in [(0.35,0.45,18),(0.6,0.38,14),(0.5,0.65,16)] {
                ctx.fill(ellipse(cx: bx * w, cy: by * h, r: br), with: .color(.white.opacity(0.35)))
            }

        // ── Color panels ──
        case .colorPanels:
            let panelColors: [Color] = [.pink, .blue, .yellow, .teal]
            let pw = w / CGFloat(panelColors.count)
            for (i, col) in panelColors.enumerated() {
                ctx.fill(Path(CGRect(x: CGFloat(i) * pw, y: 0, width: pw, height: h)), with: .color(col.opacity(0.55)))
            }

        // ── Heatmap ──
        case .heatmap:
            let heatColors: [Color] = [.blue, .green, .yellow, .red]
            for (i, col) in heatColors.enumerated() {
                let yBase = h * CGFloat(i) / 4 + h / 8
                let bulge = CGFloat(i % 2 == 0 ? 1 : -1) * 9
                var p = Path()
                p.move(to: CGPoint(x: 0, y: yBase))
                p.addQuadCurve(to: CGPoint(x: w, y: yBase), control: CGPoint(x: w / 2, y: yBase + bulge))
                ctx.stroke(p, with: .color(col.opacity(0.75)), lineWidth: 2)
            }

        // ── Gem / diamond ──
        case .liquidMetal, .gemSmoke:
            let cx = w / 2, cy = h / 2, r = min(w, h) * 0.35
            var p = Path()
            p.move(to: CGPoint(x: cx, y: cy - r))
            p.addLine(to: CGPoint(x: cx + r * 0.75, y: cy))
            p.addLine(to: CGPoint(x: cx, y: cy + r))
            p.addLine(to: CGPoint(x: cx - r * 0.75, y: cy))
            p.closeSubpath()
            ctx.stroke(p, with: .color(.white.opacity(0.65)), lineWidth: 2)

        default:
            break
        }
    }

    // MARK: Path Helpers

    private func ellipse(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }

    private func vLine(x: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: x, y: 0))
        p.addLine(to: CGPoint(x: x, y: h))
        return p
    }

    private func hLine(y: CGFloat, offset: CGFloat, w: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: y))
        p.addLine(to: CGPoint(x: w, y: y + offset))
        return p
    }

    private func ringPath(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }

    private func wavePath(yBase: CGFloat, w: CGFloat, amp: Double, freq: Double, phase: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: yBase))
        for x in stride(from: 0.0, to: w, by: 2.0) {
            p.addLine(to: CGPoint(x: x, y: yBase + CGFloat(amp * sin(x / Double(w) * .pi * freq + phase))))
        }
        return p
    }
}

// MARK: - ShaderEffect Thumbnail Colors

extension ShaderEffect {
    var thumbnailColors: [Color] {
        switch self {
        case .paperTexture:
            return [Color(red: 0.95, green: 0.92, blue: 0.85), Color(red: 0.72, green: 0.68, blue: 0.60)]
        case .flutedGlass:
            return [Color(red: 0.45, green: 0.48, blue: 0.62), Color(red: 0.18, green: 0.18, blue: 0.28)]
        case .water:
            return [Color(red: 0.08, green: 0.28, blue: 0.60), Color(red: 0.55, green: 0.78, blue: 0.95)]
        case .imageDithering:
            return [Color(white: 0.15), Color(white: 0.85)]
        case .halftoneDots:
            return [Color(white: 0.1), Color(white: 0.9)]
        case .halftoneCMYK:
            return [Color(white: 0.95)]
        case .meshGradient:
            return [Color(red: 0.8, green: 0.35, blue: 0.9), Color(red: 0.2, green: 0.55, blue: 1.0), Color(red: 0.9, green: 0.65, blue: 0.25)]
        case .staticMeshGradient:
            return [Color(red: 0.75, green: 0.28, blue: 0.88), Color(red: 0.28, green: 0.65, blue: 1.0), Color(red: 0.88, green: 0.48, blue: 0.18)]
        case .staticRadialGradient:
            return [Color(red: 0.88, green: 0.55, blue: 0.18), Color(red: 0.75, green: 0.18, blue: 0.65)]
        case .dithering:
            return [Color(white: 0.9), Color(white: 0.1)]
        case .grainGradient:
            return [Color(white: 0.08), Color(red: 0.78, green: 0.48, blue: 0.18), Color(red: 0.18, green: 0.58, blue: 0.88)]
        case .dotOrbit:
            return [Color(white: 0.05), Color(red: 0.3, green: 0.12, blue: 0.22)]
        case .dotGrid:
            return [Color(red: 0.92, green: 0.92, blue: 0.96), Color(red: 0.75, green: 0.78, blue: 0.92)]
        case .warp:
            return [Color(red: 0.25, green: 0.18, blue: 0.38)]
        case .spiral:
            return [Color(white: 0.08), Color(white: 0.25)]
        case .swirl:
            return [Color(white: 0.05), Color(red: 0.35, green: 0.08, blue: 0.48)]
        case .waves:
            return [Color(red: 0.08, green: 0.08, blue: 0.72), Color(red: 0.85, green: 0.9, blue: 1.0)]
        case .neuroNoise:
            return [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.38, green: 0.18, blue: 0.78)]
        case .perlinNoise:
            return [Color(red: 0.18, green: 0.18, blue: 0.68), Color(red: 0.88, green: 0.9, blue: 0.98)]
        case .simplexNoise:
            return [Color(red: 0.28, green: 0.75, blue: 0.88), Color(red: 0.88, green: 0.28, blue: 0.58)]
        case .voronoi:
            return [Color(red: 0.88, green: 0.28, blue: 0.38), Color(red: 0.28, green: 0.55, blue: 0.88)]
        case .pulsingBorder:
            return [Color(white: 0.03), Color(red: 0.2, green: 0.05, blue: 0.35)]
        case .metaballs:
            return [Color(white: 0.03), Color(red: 0.45, green: 0.18, blue: 0.88)]
        case .colorPanels:
            return [Color(red: 0.05, green: 0.05, blue: 0.05)]
        case .smokeRing:
            return [Color(white: 0.03), Color(red: 0.28, green: 0.12, blue: 0.08)]
        case .godRays:
            return [Color(red: 0.05, green: 0.0, blue: 0.10), Color(red: 0.35, green: 0.18, blue: 0.08)]
        case .heatmap:
            return [Color(white: 0.05), Color(red: 0.08, green: 0.08, blue: 0.25)]
        case .liquidMetal:
            return [Color(white: 0.05), Color(red: 0.15, green: 0.18, blue: 0.25)]
        case .gemSmoke:
            return [Color(white: 0.03), Color(red: 0.25, green: 0.1, blue: 0.38)]
        }
    }
}
