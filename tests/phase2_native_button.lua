local nativeButton = ISButton
ISButton = testFixtureButton
ISButton.setEnable = nativeButton.setEnable
ISButton.setBackgroundRGBA = nativeButton.setBackgroundRGBA
ISButton.setBackgroundColorMouseOverRGBA = nativeButton.setBackgroundColorMouseOverRGBA
ISButton.setBorderRGBA = nativeButton.setBorderRGBA
ISButton.setTextureRGBA = nativeButton.setTextureRGBA
