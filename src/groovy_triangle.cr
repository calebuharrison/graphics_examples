require "crystglfw"
require "crystgl"

module HelloTriangle
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

    # notice the use of two locations, which correspond with vertex attributes.
    vertex_shader_source = <<-SHADER
      #version 330 core
      layout (location = 0) in vec3 aPos;
      layout (location = 1) in vec3 aColor;
      out vec3 ourColor;
      void main()
      {
        gl_Position = vec4(aPos, 1.0);
        ourColor = aColor;
      }
    SHADER

    fragment_shader_source = <<-SHADER
      #version 330 core
      in vec3 ourColor;
      out vec4 FragColor;
      void main()
      {
        FragColor = vec4(ourColor, 1.0f);
      }
    SHADER

    window = Window.new(width: window_size[:width], height: window_size[:height], title: "Hello Triangle!", hints: hints)
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

    # vertices are now comprised of 6 values: 3 for location, 3 for color.
    vertices = {
        # ------- positions -------  --------- colors -----------
       -0.5f32,  -0.5f32,   0.0f32,   1.0f32,   0.0f32,   0.0f32, # left
        0.5f32,  -0.5f32,   0.0f32,   0.0f32,   1.0f32,   0.0f32, # right
        0.0f32,   0.5f32,   0.0f32,   0.0f32,   0.0f32,   1.0f32  # top
    }

    vertex_buffer = Buffer.new
    vertex_array  = VertexArray.new

    vertex_array.bind do
      vertex_buffer.bind(Buffer::Target::Array) do |buffer, target|
        target.buffer_data(vertices, Buffer::UsageHint::StaticDraw)
        vertex_array.define_attributes do |va|
          va.attribute(3, DataType::Float, false)
          va.attribute(3, DataType::Float, false)
        end
      end
    end

    until window.should_close?
      LibGL.clear_color(0.2, 0.3, 0.3, 1.0)
      LibGL.clear(Buffer::Bit::Color)

      program.use do
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