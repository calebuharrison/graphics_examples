require "crystglfw"
require "crystgl"

module HelloRectangle
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
        gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
      }
    SHADER

    fragment_shader_source = <<-SHADER
      #version 330 core
      out vec4 FragColor;
      void main()
      {
        FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
      }
    SHADER

    window = Window.new(width: window_size[:width], height: window_size[:height], title: "Hello Rectangle!", hints: hints)
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
        0.5f32,   0.5f32,   0.0f32, # top right
        0.5f32,  -0.5f32,   0.0f32, # bottom right
       -0.5f32,  -0.5f32,   0.0f32, # bottom left
       -0.5f32,   0.5f32,   0.0f32  # top left
    }

    # Indices used for indexed draw calls. Each is used as an index into the four vertices.
    indices = {
      0, 1, 3,  # first triangle
      1, 2, 3   # second triangle
    }

    vertex_buffer = Buffer.new
    element_buffer = Buffer.new
    vertex_array  = VertexArray.new

    vertex_array.bind do
      vertex_buffer.bind(Buffer::Target::Array) do |buffer, target|
        target.buffer_data(vertices, Buffer::UsageHint::StaticDraw)
        vertex_array.define_attributes do |va|
          va.attribute(3, DataType::Float, false)
        end
      end

      # bind the element buffer to GL_ELEMENT_ARRAY_BUFFER
      element_buffer.bind(Buffer::Target::ElementArray)

      # Send index data to the GPU.
      Buffer::Target::ElementArray.buffer_data(indices, Buffer::UsageHint::StaticDraw)
    end
    
    # unbind the element buffer.
    element_buffer.unbind

    # Note: element buffers must be bound while the target vertex array is bound, hence not using a nested block.

    until window.should_close?
      LibGL.clear_color(0.2, 0.3, 0.3, 1.0)
      LibGL.clear(Buffer::Bit::Color)

      program.use do
        vertex_array.bind do

          # Use index data to draw triangles from vertex data.
          LibGL.draw_elements(LibGL::TRIANGLES, 6, DataType::UnsignedInt, Pointer(Void).new(0))
        end
      end

      window.swap_buffers
      CrystGLFW.wait_events(0.015)
    end

    {vertex_array, vertex_buffer, element_buffer}.each { |v| v.delete }

    window.destroy
  end
end