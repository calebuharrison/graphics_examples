require "crystglfw"
require "crystgl"

module HelloWindow
  include CrystGLFW
  include CrystGL

  # initialize GLFW
  CrystGLFW.run do

    window_size = {width: 800, height: 600}

    # These hints are required for MacOS.
    hints = { 
      Window::HintLabel::ContextVersionMajor => 3,
      Window::HintLabel::ContextVersionMinor => 3,
      Window::HintLabel::OpenGLForwardCompat => true,
      Window::HintLabel::OpenGLProfile       => OpenGLProfile::Core,
      Window::HintLabel::ClientAPI           => ClientAPI::OpenGL
    }

    # Create a window and make it the current OpenGL context.
    window = Window.new(width: window_size[:width], height: window_size[:height], title: "Hello Window!", hints: hints)
    window.make_context_current

    # When a window is resized, adjust the OpenGL viewport accordingly.
    window.on_framebuffer_resize do |event|
      LibGL.viewport(0, 0, event.size[:width], event.size[:height])
      window_size = event.size
    end

    # Close the window if the user hits the escape key.
    window.on_key do |event|
      if event.action.press? && event.key.escape?
        event.window.should_close
      end
    end

    # Render loop
    until window.should_close?

      # Set the clearing color and clear the screen with that color.
      LibGL.clear_color(0.2, 0.3, 0.3, 1.0)
      LibGL.clear(Buffer::Bit::Color)

      # Swap the front and back buffers.
      window.swap_buffers

      # Using wait_events with a timeout instead of poll_events dramatically reduces CPU usage.
      CrystGLFW.wait_events(0.015)
    end

    # Destroy the window and exit.
    window.destroy
  end
end