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

    # source code for the vertex shader, declared using a Crystal heredoc.
    vertex_shader_source = <<-SHADER
      #version 330 core
      layout (location = 0) in vec3 aPos;
      void main()
      {
        gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
      }
    SHADER

    # source code for the fragment shader, declared using a Crystal heredoc.
    fragment_shader_source = <<-SHADER
      #version 330 core
      out vec4 FragColor;
      void main()
      {
        FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
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

    # Create shader objects from source and attach them to a program object.
    vertex_shader = VertexShader.create(vertex_shader_source)
    fragment_shader = FragmentShader.create(fragment_shader_source)
    shaders = {vertex_shader, fragment_shader}
    program = Program.create(shaders)

    # The 3-dimensional vertices of the triangle.
    vertices = {
       -0.5f32,  -0.5f32,   0.0f32, # left
        0.5f32,  -0.5f32,   0.0f32, # right
        0.0f32,   0.5f32,   0.0f32  # top
    }

    # Create both a vertex buffer and a vertex array object.
    vertex_buffer = Buffer.new
    vertex_array  = VertexArray.new

    # Bind the vertex array
    vertex_array.bind do

      # Bind the vertex buffer to GL_ARRAY_BUFFER
      vertex_buffer.bind(Buffer::Target::Array) do |buffer, target|
        
        # Send the vertex data to the GPU
        target.buffer_data(vertices, Buffer::UsageHint::StaticDraw)

        # Tell the vertex array how to interpret the vertex data using attributes.
        vertex_array.define_attributes do |va|

          # Declare the location attribute
          va.attribute(3, DataType::Float, false)
        end # <- stops defining attributes.
      end # <- unbinds the vertex buffer.
    end # <- unbinds the vertex array.

    until window.should_close?
      LibGL.clear_color(0.2, 0.3, 0.3, 1.0)
      LibGL.clear(Buffer::Bit::Color)

      # Use the program object
      program.use do 

        # Bind the vertex array.
        vertex_array.bind do

          # Use the data, as interpreted by the vertex array, to draw triangles.
          LibGL.draw_arrays(LibGL::TRIANGLES, 0, 3)
        end # <- unbinds the vertex array
      end # <- stops using the program object

      window.swap_buffers
      CrystGLFW.wait_events(0.015)
    end

    {vertex_array, vertex_buffer}.each { |v| v.delete }

    window.destroy
  end
end