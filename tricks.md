# Mech Interp Tricks & Tips

## 1. Multiplying `FactoredMatrix` with PyTorch Tensors

When using the `FactoredMatrix` class (from `transformer_lens`) to analyze low-rank factored matrices, you will often want to compute the full circuit by pre-multiplying by the embedding matrix (`W_E`) and post-multiplying by the unembedding matrix (`W_U`).

### The Problem
If you try to pass a `FactoredMatrix` object into the `FactoredMatrix` constructor, it will fail:
```python
# ❌ INCORRECT: This will raise an error because FactoredMatrix expects raw Tensors.
ovu = FactoredMatrix(l1h4_factored_matrix, model.W_U)
full_OV_circuit = FactoredMatrix(model.W_E, ovu)
```

### The Solution (The `@` operator trick)
`FactoredMatrix` overrides the `@` matrix multiplication operator. You can chain multiplications with raw PyTorch tensors directly using `@`. The class is smart enough to perform the multiplication on the correct low-rank components under the hood without materializing the full matrix:

```python
# W_V and W_O are PyTorch tensors
OV_circuit = FactoredMatrix(W_V, W_O) 

# W_E and W_U are PyTorch tensors. We can chain them directly:
# ✅ CORRECT & EFFICIENT:
full_OV_circuit = model.W_E @ OV_circuit @ model.W_U
```

This returns a new `FactoredMatrix` representing the product `(W_E @ W_V) @ (W_O @ W_U)`.
