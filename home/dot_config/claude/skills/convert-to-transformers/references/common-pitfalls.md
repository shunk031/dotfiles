# Common Pitfalls & Solutions

Detailed troubleshooting guide for Hugging Face Transformers model conversion.

## 1. Hardcoded Values

**Problem**: Original model has magic numbers scattered throughout.

**Solution**:

- Create config parameter for each hardcoded value
- Set defaults matching pretrained weights
- Document what each parameter controls

Example:

```python
# Bad - in original
self.conv = nn.Conv2d(64, 128, 3)

# Good - in config
self.hidden_dim1 = 64  # Default matches pretrained
self.hidden_dim2 = 128

# Good - in model
self.conv = nn.Conv2d(config.hidden_dim1, config.hidden_dim2, 3)
```

## 2. Preprocessing Mismatches

**Problem**: Subtle differences in resize, normalize, or tensor conversion.

**Solution**:

- Use EXACT same preprocessing pipeline
- For PIL Image.resize, match the resampling method (BILINEAR, BICUBIC, etc.)
- For normalization, match mean/std exactly
- Test preprocessing separately before testing full model

## 3. Output Format Differences

**Problem**: Original returns tensor, Transformers expects specific output format.

**Solution**:

- Use appropriate `ModelOutput` class (SemanticSegmenterOutput, etc.)
- Support `return_dict` parameter
- Provide tuple output for backward compatibility

## 4. State Dict Key Mismatches

**Problem**: Cannot load pretrained weights due to key name differences.

**Solution**:

- Keep layer names matching original as much as possible
- If names must change, create mapping function
- Test `load_state_dict` early in development

## 5. Batch Size Assumptions

**Problem**: Original model assumes batch size = 1.

**Solution**:

- Test with various batch sizes
- Avoid hardcoding batch-specific operations
- Use `batch_size = x.shape[0]` instead of `batch_size = 1`

## 6. Device Handling

**Problem**: Tensors on different devices causing errors.

**Solution**:

- Use `self.device` from PreTrainedModel
- Move all tensors to same device in forward pass
- Handle positional encodings and buffers properly

Example:

```python
# For modules with buffers
for module in model.modules():
    if hasattr(module, "positional_encoding"):
        if hasattr(module.positional_encoding, "pos_embed"):
            module.positional_encoding.pos_embed = (
                module.positional_encoding.pos_embed.to(device)
            )
```

## 7. Test Tolerance Too Strict

**Problem**: Tests fail due to tiny numerical differences.

**Solution**:

- Use appropriate tolerance (5e-3 or 0.5% is reasonable)
- Understand that float32 arithmetic has inherent imprecision
- Focus on relative error, not absolute
- When comparing, ensure SAME tensor is used for both models

**Example from MVANet experience**:

```python
# WRONG - causes false mismatch (double preprocessing)
inputs = processor(original_image, ...)  # Resizes from original
old_out = old_model(predictor.transform(original_image))  # Resizes again

# RIGHT - ensures exact comparison
preprocessed = predictor.transform(original_image)  # Preprocess ONCE
old_out = old_model(preprocessed)
new_out = new_model(preprocessed)  # Same tensor
```

## 8. Image Size Order

**Problem**: Width and height swapped in post-processing.

**Solution**:

- `post_process_semantic_segmentation()` expects `target_sizes` as `(width, height)`
- PIL `Image.size` returns `(width, height)` ✓
- PIL `Image.width` and `Image.height` properties exist separately

**Correct usage**:

```python
# Correct
target_sizes = [(img.width, img.height) for img in images]
# or
w, h = img.size
target_sizes = [(w, h)]

# Wrong - causes width/height swap
target_sizes = [(img.height, img.width)]
```

## 9. Auto\* Class Registration

**Problem**: `from_pretrained()` fails after pushing to Hub.

**Solution**:

- Must call `register_for_auto_class()` on each class before pushing
- Add registration in `__init__.py` so it happens on module import

```python
# In __init__.py
ModelConfig.register_for_auto_class()
ModelForTask.register_for_auto_class("AutoModel")
ImageProcessor.register_for_auto_class("AutoImageProcessor")
```

## Debugging Strategy

If outputs don't match:

### 1. Check Preprocessing

Do both implementations produce identical tensors?

```python
old_tensor = old_preprocessing(image)
new_tensor = processor(image, return_tensors="pt")["pixel_values"][0]
print(f"Max diff: {torch.max(torch.abs(old_tensor - new_tensor))}")
```

### 2. Check State Dict

Are all weights loaded correctly?

```python
new_model = NewModel(NewConfig())
missing, unexpected = new_model.load_state_dict(old_model.state_dict(), strict=False)
print(f"Missing keys: {missing}")
print(f"Unexpected keys: {unexpected}")
```

### 3. Step-by-Step Comparison

Compare each layer's output:

```python
with torch.no_grad():
    # Layer 1
    old_l1 = old_model.layer1(x)
    new_l1 = new_model.layer1(x)
    print(f"Layer 1 diff: {torch.max(torch.abs(old_l1 - new_l1))}")

    # Layer 2
    old_l2 = old_model.layer2(old_l1)
    new_l2 = new_model.layer2(new_l1)
    print(f"Layer 2 diff: {torch.max(torch.abs(old_l2 - new_l2))}")

    # Continue for all layers
```

### 4. Check Device Placement

Are all tensors on the same device?

```python
print(f"Model device: {next(model.parameters()).device}")
print(f"Input device: {x.device}")
```

### 5. Check Determinism

Set seed for reproducibility:

```python
torch.manual_seed(42)
torch.cuda.manual_seed_all(42)
torch.backends.cudnn.deterministic = True
```

### 6. Isolate Differences

Binary search to find where outputs diverge:

1. Test full model → Difference found
2. Test first half → No difference
3. Test second half → Difference found
4. Test first quarter of second half → etc.

This narrows down the problematic layer/module.
