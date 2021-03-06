require "crystglfw"
require "crystgl"

module PulsingTriangle
  include CrystGLFW
  include CrystGL

  CrystGLFW.run do

    window_size = {width: 800, height: 600}

    hints = { 
      Window::HintLabel::ContextVersionMajor => 3,
      Window::HintLabel::ContextVersionMinor => 3,
      Window::HintLabel::OpenGLForwardCompat => true,
      Window::HintLabel::OpenGLProfile       => OpenGLProfile::Core,
      Window::HintLabel::ClientAPI           => ClientAPI::OpenGL
    }

    vertex_shader_source = <<-SHADER
      #version 330 core
      layout (location = 0) in vec3 aPos;
      void main()
      {
        gl_Position = vec4(aPos, 1.0);
      }
    SHADER

    # notice that a uniform called 'ourColor' is declared, and FragColor is set to its value.
    fragment_shader_source = <<-SHADER
      #version 330 core
      uniform vec4 ourColor;
      out vec4 FragColor;
      void main()
      {
        FragColor = ourColor;
      }
    SHADER

    window = Window.new(width: window_size[:width], height: window_size[:height], title: "Pulsing Triangle!", hints: hints)
    window.make_context_current

    window.on_framebuffer_resize do |event|
      LibGL.viewport(0, 0, event.size[:width], event.size[:height])
      window_size = event.size
    end

    window.on_key do |event|
      if event.action.press? && event.key.escape?
        event.window.should_close
      end
    end

    vertex_shader = VertexShader.create(vertex_shader_source)
    fragment_shader = FragmentShader.create(fragment_shader_source)
    shaders = {vertex_shader, fragment_shader}
    program = Program.create(shaders)

    vertices = {
       -0.5f32,  -0.5f32,   0.0f32, # left
        0.5f32,  -0.5f32,   0.0f32, # right
        0.0f32,   0.5f32,   0.0f32  # top
    }

    vertex_buffer = Buffer.new
    vertex_array  = VertexArray.new

    vertex_array.bind do
      vertex_buffer.bind(Buffer::Target::Array) do |buffer, target|
        target.buffer_data(vertices, Buffer::UsageHint::StaticDraw)
        vertex_array.define_attributes do |va|
          va.attribute(3, DataType::Float, false)
        end
      end
    end

    until window.should_close?
      LibGL.clear_color(0.2, 0.3, 0.3, 1.0)
      LibGL.clear(Buffer::Bit::Color)

      # Calculate a green value using the GLFW timer.
      green_value = Math.sin(CrystGLFW.time).abs.to_f32

      program.use do |p|
        
        # Set the value of the uniform named 'ourColor' to the 4-dimensional vector constructed from the other args.
        p.set_uniform("ourColor", 0.0f32, green_value, 0.0f32, 1.0f32)
        vertex_array.bind do
          LibGL.draw_arrays(LibGL::TRIANGLES, 0, 3)
        end
      end

      window.swap_buffers
      CrystGLFW.wait_events(0.015)
    end

    {vertex_array, vertex_buffer}.each { |v| v.delete }

    window.destroy
  end
end