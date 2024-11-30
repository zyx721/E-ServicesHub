import onnx
from onnx_tf.backend import prepare

# Load the ONNX model
onnx_model = onnx.load("mobilenet_model.onnx")

# Convert to TensorFlow model
tf_rep = prepare(onnx_model)

# Export to TensorFlow
tf_rep.export_graph("mobilenet_model.pb")

print("Model converted to TensorFlow format successfully.")
