require_relative '../../../bindings/ruby/bgfx'
require_relative '../imgui'
require_relative '../imgui_impl_bgfx'

class SampleDialog

  def self.open_browser(url)
    case RUBY_PLATFORM
    when /mswin|msys|mingw|cygwin/
      system("start", url)
    when /darwin/
      system("open", url)
    else
      raise RuntimeError, "Unknown OS: #{RUBY_PLATFORM}"
    end
  end

  def self.show(sample)
    ImGui::SetNextWindowPos(ImVec2.create(10.0, 50.0), ImGuiCond_FirstUseEver)
    ImGui::SetNextWindowSize(ImVec2.create(300.0, 210.0), ImGuiCond_FirstUseEver)
    ImGui::Begin(sample.name)
    ImGui::TextWrapped("%s", :string, sample.desc)
    # if ImGui::IsItemHovered()
    #   ImGui::BeginTooltip()
    #   ImGui::PushTextWrapPos(ImGui::GetFontSize() * 35.0)
    #   ImGui::TextWrapped("%s", :string, sample.desc)
    #   ImGui::PopTextWrapPos()
    #   ImGui::EndTooltip()
    # end

    ImGui::SameLine()
    if ImGui::Button("Doc")
      open_browser(sample.url)
    elsif ImGui::IsItemHovered()
      ImGui::SetTooltip("Documentation: %s", :string, sample.url)
    end
    ImGui::Separator()
    ImGui::End()

    ImGui::Separator()

  end

end
