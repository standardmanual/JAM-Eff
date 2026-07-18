import SwiftUI

// MARK: - ParamPanelView (Zone 4)

struct ParamPanelView: View {
    @EnvironmentObject var session: EditSession
    @State private var layoutExpanded: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if let idx = selectedIndex, session.shaderStack.indices.contains(idx) {
                let layerBinding = Binding(
                    get: { session.shaderStack[idx] },
                    set: { session.shaderStack[idx] = $0 }
                )
                paramContent(layerBinding: layerBinding, layer: session.shaderStack[idx])
            } else {
                Text("레이어를 선택하거나 추가하세요")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            }
        }
        .background(.regularMaterial)
    }

    private var selectedIndex: Int? {
        let idx = session.selectedLayerIndex
        guard session.shaderStack.indices.contains(idx) else { return nil }
        return idx
    }

    @ViewBuilder
    private func paramContent(layerBinding: Binding<ShaderLayer>, layer: ShaderLayer) -> some View {
        if layer.isImageLayer {
            imageLayerContent
        } else {
            shaderParamContent(layerBinding: layerBinding, layer: layer)
        }
    }

    @ViewBuilder
    private var imageLayerContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 32))
                .foregroundStyle(Color.secondary)
            Text("사진 레이어")
                .font(.system(size: 15, weight: .medium))
            Text("프리뷰에서 핀치/드래그로 크기와 위치를 조정할 수 있어요")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    @ViewBuilder
    private func shaderParamContent(layerBinding: Binding<ShaderLayer>, layer: ShaderLayer) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: 색상 섹션
            let colorKeys = colorKeys(layer: layer)
            if !colorKeys.isEmpty {
                SectionHeader(title: "색상")
                ForEach(colorKeys, id: \.self) { key in
                    colorRow(key: key, layerBinding: layerBinding, layer: layerBinding.wrappedValue)
                    Divider().padding(.horizontal, 16)
                }
            }

            // MARK: 조절 섹션
            let adjustKeys = adjustKeys(layer: layer)
            if !adjustKeys.isEmpty {
                SectionHeader(title: "조절")
                ForEach(adjustKeys, id: \.self) { key in
                    adjustRow(key: key, layerBinding: layerBinding, layer: layerBinding.wrappedValue)
                    Divider().padding(.horizontal, 16)
                }
            }

            // MARK: 레이아웃 섹션 (접기/펼치기)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    layoutExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: layoutExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("레이아웃")
                        .font(.headline)
                }
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(height: 44)
            }
            .buttonStyle(.plain)

            if layoutExpanded {
                ForEach(layer.effectType?.layoutParamKeys ?? [], id: \.self) { key in
                    adjustRow(key: key, layerBinding: layerBinding, layer: layerBinding.wrappedValue)
                    Divider().padding(.horizontal, 16)
                }
            }

            Spacer(minLength: 40)
        }
    }

    // MARK: - Color param display order

    private func colorKeys(layer: ShaderLayer) -> [String] {
        layer.params.keys.filter { key in
            switch layer.params[key] {
            case .color, .colors: return true
            default: return false
            }
        }.sorted()
    }

    private func adjustKeys(layer: ShaderLayer) -> [String] {
        let layoutKeys = Set(layer.effectType?.layoutParamKeys ?? [])
        return layer.params.keys.filter { key in
            if layoutKeys.contains(key) { return false }
            switch layer.params[key] {
            case .float, .bool, .enumInt: return true
            default: return false
            }
        }.sorted()
    }

    @ViewBuilder
    private func colorRow(key: String, layerBinding: Binding<ShaderLayer>, layer: ShaderLayer) -> some View {
        switch layer.params[key] {
        case .color:
            ColorParamRow(name: key, paramKey: key, layer: layerBinding)
        case .colors:
            ColorsParamRow(name: key, paramKey: key, layer: layerBinding)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func adjustRow(key: String, layerBinding: Binding<ShaderLayer>, layer: ShaderLayer) -> some View {
        switch layer.params[key] {
        case .float:
            FloatParamRowBound(name: key, paramKey: key, layer: layerBinding)
        case .bool:
            BoolParamRow(name: key, paramKey: key, layer: layerBinding)
        case .enumInt:
            EnumParamRow(name: key, paramKey: key, layer: layerBinding)
        default:
            EmptyView()
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}
